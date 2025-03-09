import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import 'asym_crypto.dart';

class Network {
  static bool _allowJunk = false;         //If false, the client will shut down the connection if it receives any junk data from the server. Usually true when the client is already authenticated.
  static WebSocketChannel? _serverSock;
  static RSAPublicKey? _publicKey;
  static RSAPrivateKey? _privateKey;
  static String? _userID;
  static String? _tokenID;
  static Uint8List? _tokenSecret;
  static final wbsAddressRegex = RegExp(r'^wss?:\/\/[\w\d\.\-]+(:\d{1,5})?$');

  //Enforce a Singleton design; only one instance of this class can exist
  static final Network instance = Network._constructor();
  factory Network() {
    return instance;
  }
  Network._constructor();


  //Method: importKeys().
  //Imports the given RSA private key and derives the corresponding RSA public key.
  //Only works if the WebSocketChannel is null (implied: there is no active connection).
  //Parameters: The user's private key.
  //Returns: Nothing; just modifies the Network object. Raises an exception if there's an active connection.
  void setUserKeypair(RSAPrivateKey privateKey) {
    if (_serverSock != null) {
      throw ValueFrozenByNetworkConnection();
    }

    //Make sure we have a complete key; for some reason PointyCastle returns nullable components for its keys
    if (privateKey.modulus == null || privateKey.privateExponent == null || privateKey.p == null || privateKey.q == null || privateKey.publicExponent == null) {
      throw FormatException("Incomplete private key received!");
    }
    _privateKey = privateKey;
    final n = privateKey.modulus;
    final e = privateKey.publicExponent;
    _publicKey = RSAPublicKey(n!, e!);
  }

  RSAPublicKey? getUserPublicKey() {
    return _publicKey;
  }

  //Closes the connection when server junk isn't allowed (i.e. in authentication contexts).
  void handleJunk() {
    if (! _allowJunk) {
      print("Network.handleJunk(): Junk isn't allowed; closing the connection.");
      _serverSock!.sink.close();
      _serverSock = null;
    }
    return;
  }

  //Method: connect().
  //Connects to the specified WebSocket server address and stores the resulting WebSocketChannel inside this object.
  //This should NOT be used by external customers to connect to the server; it does not configure a listener nor authenticate.
  //Parameters: Server's WebSocket address.
  //Returns: nothing if successful; an error or exception if failure occurred.
  Future<void> _connect(String serverWbsAddr) async {
    //Ensure we have a valid WebSocket address. Thanks Regex!
    if (! wbsAddressRegex.hasMatch(serverWbsAddr)) {
      throw FormatException('Invalid WebSocket URL given. Should be of format: ws[s]://myFQDN.tld:port or ws[s]://0.0.0.0:port');
    }

    //Ensure we have a valid RSA keypair set.
    //If not, authentication will fail and the code relying on it will malfunction.
    if (_publicKey == null || _privateKey == null) {
      throw AuthenticationKeypairMissing();
    }

    //Parse the URL and connect to the server.
    final wsUrl = Uri.parse(serverWbsAddr);
    final channel = WebSocketChannel.connect(wsUrl);
    await channel.ready;
    _serverSock = channel;
  }

  Future<void> connectAndAuth(String serverWbsAddr) async {
    await _connect(serverWbsAddr);
    _serverSock!.stream.listen((message) {
      _handleServerResponse(message);
    }, onDone: () {
      print("The stream is closed!");
      _serverSock = null;
    }, onError: (error) {
      print("Stream received error: " + error.toString());
      _serverSock = null;
    });
    
  }

  //Method: _handleServerResponse().
  //Serves as the principal handler method for any data received through the serverSock.
  //Parameters: The data received from the socket.
  //Returns: Nothing to the caller. It isn't intended for external customers.
  void _handleServerResponse(message) {
    print("Received message!");
    print(message);
  
    //Decode and verify the message
    var parsedMsg = jsonDecode(message);
    print("Decoded the message.");
    print(parsedMsg.runtimeType);
  
    if (parsedMsg is! Map) {
      //This is likely junk data. The real server only sends JSON messages.
      print('Got an invalid message.');
      handleJunk();
      return;
    }
  
    if (!(parsedMsg.containsKey('Command'))) {
      //Also likely junk data. The server always sends a command.
      print("Response is missing the Command key.");
      handleJunk();
      return;
    }

    switch (parsedMsg['Command'].toString().toUpperCase()) {
      case 'PING':
        print("Received a PING from the server.");
      
      case 'CONNECT':
        return _handleAuthChallenge(parsedMsg);
      
      case 'AUTH':
        _handleAuthResponse(parsedMsg);
        print("Process complete.");
        print(_tokenID);
        print(_userID);
    }
  }

/*
HANDLER FUNCTIONS
These are helper functions that assist the main message handler function.
Each of these handles a specific kind of message.
*/

  void _handleAuthChallenge(Map responseMsg) {
    if (! _isValidAuthChallenge(responseMsg)) {
      print("Network.handleAuthChallenge(): Received invalid challenge from server!");
      handleJunk();
      return;
    }
    if (_privateKey == null) {
      print("Network.handleAuthChallenge(): The user's RSA private key is missing!");
      print("Closing the connection and aborting.");
      _serverSock!.sink.close();
      _serverSock = null;
      throw AuthenticationKeypairMissing();
    }

    //Decode the binary challenge data and sign it.
    final b64d = Base64Decoder();
    final challengeId = responseMsg['ChallengeId'];
    final challengeData = b64d.convert(responseMsg['ChallengeData']);
    final sigBytes = rsaSignSHA256(_privateKey!, challengeData).bytes;
    final authRequest = _constructAuthRequest(challengeId, sigBytes);
    print("Sending an authentication request.");
    _serverSock!.sink.add(authRequest);
    return;
  }

  void _handleAuthResponse(Map responseMsg) {
    if (! _isValidAuthResponse(responseMsg)) {
      print("Network.handleAuthResponse(): Received invalid response from server!");
      handleJunk();
      return;
    }
    _userID = responseMsg['UserId'];
    if (! _isTokenPresent(responseMsg)) {
      //We need a proper token before we can communicate.
      //Restart the authentication process, but as a registered user.
      final loginRequest = _constructLoginRequest(_publicKey!, _userID!);
      _serverSock!.sink.add(loginRequest);
      return;
    }
    //Token is present.
    //Save the token and then close the connection so that the caller knows we're authenticated.
    _tokenID = responseMsg['TokenId'];
    const b64d = Base64Decoder();
    _tokenSecret = b64d.convert(responseMsg['TokenSecret']);
    _serverSock!.sink.close();
    _serverSock = null;
    _allowJunk = true;
  }

/*
AUXILIARY FUNCTIONS
These are helper functions that assist the main functions.
Can vary from data integrity checks to sub-functions.
*/

  //Checks a given JSON data structure and confirms if all of the required keys are present.
  bool _isValidAuthChallenge(Map responseData) {
    //Ensure all required keys are present
    const requiredKeys = ['Command','ChallengeId','ChallengeData','Successful'];
    for (final rkey in requiredKeys) {
      if (!responseData.containsKey(rkey)) {
        print("Required key " + rkey + " is missing!");
        return false;
      }
    }

    //Ensure all required keys have the right values and types
    if (responseData['Command'].toString().toUpperCase() != 'CONNECT') return false;
    if (responseData['ChallengeId'] is! String) return false;
    if (responseData['ChallengeData'] is! String) return false;

    //Ensure no blank values
    if (responseData['ChallengeId'] == '') return false;
    if (responseData['ChallengeData'] == '') return false;

    return true;
  }

  //Determine if a server's response to an authentication request is valid.
  //Does NOT check if a valid token was attached or not.
  bool _isValidAuthResponse(Map responseData) {
    const requiredKeys = ['Command','Successful','UserId','TokenId','TokenSecret'];
    for (final rkey in requiredKeys) {
      if (!responseData.containsKey(rkey)) {
        print("Required key " + rkey + " is missing!");
        return false;
      }
    }
    //Ensure all required keys have the right values and types
    if (responseData['Command'].toString().toUpperCase() != 'CONNECT') return false;
    if (responseData['UserId'] is! String) return false;
    if (responseData['TokenId'] is! String) return false;
    if (responseData['TokenSecret'] is! String) return false;

    //Ensure no blank values
    if (responseData['UserId'] == '') return false;

    //This function does NOT check for a missing token.
    //It is rarely possible that the server registered the user but failed to issue a token.
    //In that case, that issue can be resolved with a new login request.
    return true;
  }

  //Checks if a valid token was attached to an authentication response.
  bool _isTokenPresent(Map responseData) {
    const requiredKeys = ['TokenId','TokenSecret'];
    for (final rkey in requiredKeys) {
      if (!responseData.containsKey(rkey)) {
        print("Required key " + rkey + " is missing!");
        return false;
      }
    }
    if (responseData['TokenId'] is! String) return false;
    if (responseData['TokenSecret'] is! String) return false;

    //Ensure no blank values
    if (responseData['TokenId'] == '') return false;
    if (responseData['TokenSecret'] == '') return false;
    
    return true;
  }


  String _constructLoginRequest(RSAPublicKey userPublicKey, String userID) {
    final currentTime = DateTime.timestamp();
    final loginRequest = {
      'Command':'CONNECT',
      'UserPublicKeyMod': userPublicKey.modulus.toString(),
      'UserPublicKeyExp': userPublicKey.publicExponent.toString(),
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt(), //Server only accepts second-level accuracy and Dart doesn't provide that natively
      'Register': 'False',
      'UserId': userID,
    };
    const encoder = JsonEncoder();
    return encoder.convert(loginRequest);
  }

  String _constructRegisterRequest(RSAPublicKey userPublicKey) {
    final currentTime = DateTime.timestamp();
    final loginRequest = {
      'Command':'CONNECT',
      'UserPublicKeyMod': userPublicKey.modulus.toString(),
      'UserPublicKeyExp': userPublicKey.publicExponent.toString(),
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt(), //Server only accepts second-level accuracy and Dart doesn't provide that natively
      'Register': 'True',
    };
    const encoder = JsonEncoder();
    return encoder.convert(loginRequest);
  }

  String _constructAuthRequest(String challengeID, Uint8List signatureBytes) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    final connectRequest = {
      'Command':'AUTHENTICATE',
      'ChallengeId':challengeID,
      'Signature': b64.convert(signatureBytes),
      'HashAlgorithm':'SHA256',
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    const encoder = JsonEncoder();
    return encoder.convert(connectRequest);
  }

}
//Throw this exception when a Network object is asked to change critical info while connected to a server.
class ValueFrozenByNetworkConnection implements Exception {
  const ValueFrozenByNetworkConnection(): super();
}

//Throw this exception when a Network object is instructed to connect and doesn't have its RSA keypair yet.
class AuthenticationKeypairMissing implements Exception {
  const AuthenticationKeypairMissing(): super();
}