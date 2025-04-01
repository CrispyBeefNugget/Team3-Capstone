import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:dmaft/asym_crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:pointycastle/export.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

class Network {
  static final _defaultServerURL = 'wss://10.0.2.2:8765';
  static var _serverURL = '';
  static var _opsInProgress = Map();
  static bool _allowJunk = false;         //If false, shut down the connection if it receives any junk data from the server. False in pre-auth or auth contexts; True in post-auth contexts.
  static WebSocketChannel? _serverSock;   //The WebSocket connection to the server is stored here while active.
  late final StreamController clientSock;   //The send-to-client event stream is stored here while a server WebSocket connection is active. Gets initialized in the constructor.
  static RSAPublicKey? _publicKey;
  static RSAPrivateKey? _privateKey;
  static String? _userID;
  static String? _tokenID;
  static Uint8List? _tokenSecret;
  static bool connected = false;
  static bool _authInProgress = false;
  static int _maxRetries = 5;
  static int _retryCount = 0;
  static final wbsAddressRegex = RegExp(r'^wss?:\/\/[\w\d\.\-]+(:\d{1,5})?$');

  //Enforce a Singleton design; only one instance of this class can exist
  static final Network instance = Network._constructor();
  factory Network() {
    return instance;
  }
  Network._constructor() {
    resetServerURL();
    clientSock = StreamController(
    onPause: () => _stopServerConnection(),
    onResume: () => print("Please connect manually."),
    onCancel: () => _stopServerConnection(),
    onListen: () => print("Please connect manually."),
  );
  }

  //GETTER/SETTER METHODS START HERE
  String getServerURL() {
    return _serverURL;
  }

  void setServerURL(String newServerURL) {
    _serverURL = newServerURL;
  }

  void resetServerURL() {
    _serverURL = _defaultServerURL;
  }

  void initRandomUserKeys() {
    final pair = generateRSAkeyPair(exampleSecureRandom());
    try {
      _publicKey = pair.publicKey;
      _privateKey = pair.privateKey;
      print("Successfully set a random user keypair.");
    }
    catch(e) {
      print("User keypair has already been set and cannot be changed.");
    }
  }

  void _leakPrivateKey() {
    if (_privateKey != null) {
      print("Private key (p, q, n, e, d):");
      print(_privateKey!.p);
      print(_privateKey!.q);
      print(_privateKey!.n);
      print(_privateKey!.publicExponent);
      print(_privateKey!.privateExponent);
    }
    return;
  }

  void setUserID(String userID) {
    _userID = userID;
    return;
  }

  String? getUserID() {
    return _userID;
  }


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

  void setToken(String tokenID, Uint8List tokenSecret) {
    _tokenID = tokenID;
    _tokenSecret = tokenSecret;
    return;
  }

  //Might only disclose the ID later on for security.
  //However, at some point the client NEEDS to get the TokenSecret to store it.
  //Considering that, might as well just provide everything.
  Map getToken() {
    return {'TokenID':_tokenID, 'TokenSecret':_tokenSecret};
  }

  bool isOnline() {
    return (_serverSock != null);
  }

  //GENERAL INTERNAL USE METHODS HERE

  //Method: operationSuccess
  //Returns a Future and waits until the given Operation ID key
  //in _opsInProgress is assigned a true (successful) or false (failed) value.
  //If operationID isn't a valid key in _opsInProgress, this returns false.
  //NOTE: This ALSO deletes the operation once done from _opsInProgress.
  Future<bool> operationSuccess(String operationID) async {
    try {
      late bool answer;
      await Future.doWhile(() => _opsInProgress[operationID] == null);
      if (_opsInProgress[operationID] == true) {
        answer = true;
      }
      else {
        answer = false;
      }
      _opsInProgress.remove(operationID);
      return answer;
    }
    catch(e) {
      return false;
    }
  }

  Future<void> waitUntilConnected() async {
    Future.doWhile(() => (connected == false));
  }

  //UI-FACING MESSAGE SENDING COMMANDS

  //Method: sendTextMessage
  Future<void> sendTextMessage(String conversationID, String msgToSend, String msgID) async {
    if (!_isUiListening()) {
      throw NetworkStreamListenerRequired();
    }
    if (_authInProgress) {
      print("Authentication is already in progress, waiting...");
      waitUntilConnected().then((data) {
        print("Making the message!");
        var requestJson = _constructSendTextMessageRequest(conversationID, msgToSend, msgID);
        print(requestJson);
        print("Sending the message now!");
        _serverSock!.sink.add(requestJson);
      });
    }
    else {
      print("Authentication not started yet, starting...");
      connectAndAuth().then((data) {
        print("Making the message!");
        var requestJson = _constructSendTextMessageRequest(conversationID, msgToSend, msgID);
        print("Sending the message now!");
        _serverSock!.sink.add(requestJson);
      });
    }
  }

  //Method: createNewConversation
  Future<void> createNewConversation(List<String> recipientIDs) async {
    if (!_isUiListening()) {
      throw NetworkStreamListenerRequired();
    }
    if (_authInProgress) {
      print("Authentication is already in progress, waiting...");
      waitUntilConnected().then((data) {
        print("Making the new conversation request!");
        var requestJson = _constructNewConversationRequest(recipientIDs);
        print(requestJson);
        print("Sending the new conversation request now!");
        _serverSock!.sink.add(requestJson);
      });
    }
    else {
      print("Authentication not started yet, starting...");
      connectAndAuth().then((data) {
        print("Making the new conversation request!");
        var requestJson = _constructNewConversationRequest(recipientIDs);
        print(requestJson);
        print("Sending the new conversation request now!");
        _serverSock!.sink.add(requestJson);
      });
    }
  }

  //Method: leaveConversation
  Future<void> leaveConversation(String conversationID) async {
    if (!_isUiListening()) {
      throw NetworkStreamListenerRequired();
    }
    if (_authInProgress) {
      print("Authentication is already in progress, waiting...");
      waitUntilConnected().then((data) {
        print("Making the leave conversation request!");
        var requestJson = _constructLeaveConversationRequest(conversationID);
        print(requestJson);
        print("Sending the leave conversation request now!");
        _serverSock!.sink.add(requestJson);
      });
    }
    else {
      print("Authentication not started yet, starting...");
      connectAndAuth().then((data) {
        print("Making the leave conversation request!");
        var requestJson = _constructLeaveConversationRequest(conversationID);
        print(requestJson);
        print("Sending the leave conversation request now!");
        _serverSock!.sink.add(requestJson);
      });
    }
  }

  //Method: searchServerUsers
  Future<void> searchServerUsers(String nameOrID, bool searchByID) async {
    if (!_isUiListening()) {
      throw NetworkStreamListenerRequired();
    }
    if (_authInProgress) {
      print("Authentication is already in progress, waiting...");
      waitUntilConnected().then((data) {
        print("Making the user search request!");
        var requestJson = _constructSearchUserRequest(nameOrID, searchById: searchByID);
        print(requestJson);
        print("Sending the user search request now!");
        _serverSock!.sink.add(requestJson);
      });
    }
    else {
      print("Authentication not started yet, starting...");
      connectAndAuth().then((data) {
        print("Making the user search request!");
        var requestJson = _constructSearchUserRequest(nameOrID, searchById: searchByID);
        print(requestJson);
        print("Sending the user search request now!");
        _serverSock!.sink.add(requestJson);
      });
    }
  }



  //CLIENT STREAM HANDLER METHODS HERE

  //Method: _startServerConnection().
  //Directs this object to connect to the currently-set server URL.
  //This method should only be called by the _clientSock StreamController,
  //when the UI starts listening for network connectivity.
  void _startServerConnection() async {
    try {
      if ((_userID != null) && (_tokenID != null) && (_tokenSecret != null)) {
        _allowJunk = true;
        await _connect(_serverURL);
        connected = true;
        clientSock.add("To the UI: successfully connected to server!");
      }
      else {
        _allowJunk = false;
        await connectAndAuth();
        connected = true;
        clientSock.add("To the UI: successfully connected and authenticated to server!");
      }
    }
    catch (e) {
      connected = false;
      clientSock.add("Failed to connect to server URL " + _serverURL);
    }
  }

  void _stopServerConnection() {
    connected = false;
    _disconnect(_allowJunk);
  }

  bool _isUiListening() {
    return (clientSock.hasListener || !clientSock.isPaused || !clientSock.isClosed);
  }


  /*
  SERVER-SIDE SOCKET HANDLING METHODS GO HERE.
  THESE ARE INTENDED ONLY FOR INTERNAL USE.
  */

  //Closes the connection when server junk isn't allowed (i.e. in authentication contexts).
  void handleJunk() {
    if (! _allowJunk) {
      print("Network.handleJunk(): Junk isn't allowed; closing the connection.");
      _disconnect(_allowJunk);
    }
    return;
  }

  //Method: _connect().
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
    //connected = true; Purposely leaving this alone since other methods should modify this variable.
  }

  //Method: _disconnect().
  //Disconnects from the currently-connected WebSocket server.
  //Does NOT impact the client-side stream in any way.
  void _disconnect(bool allowJunkNextTime) async {
    try {
      await _serverSock!.sink.close(3000);
      _serverSock = null;
    }
    catch (e) {
      //Do nothing.
      //If we fell into here, the server socket was probably null.
    }
    connected = false;
    _allowJunk = allowJunkNextTime;
  }

  //Method: connectAndAuth().
  //Confirms that a valid RSA keypair is set, then starts a network
  //connection to the specified server and attempts to authenticate.
  //Parameters: None, uses the object's _serverURL.
  //Returns: Nothing if successful, an exception if unsuccessful.
  Future<bool> connectAndAuth() async {
    if (connected) return true; //If we're already connected, tell the caller and exit.
    if (_authInProgress) return false; //Another copy of this method is trying to authenticate. Stop.
    
    _authInProgress = true;
    await _connect(_serverURL);
    
    //Generate and send a challenge BEFORE configuring the listener.
    //We're configuring the listener to block until it's done for authentication.

    var connectRequest = '';
    if (_userID == null) {
      connectRequest = _constructRegisterRequest(_publicKey!);
    }
    else {
      connectRequest = _constructLoginRequest(_publicKey!, _userID!);
    }

    print('Sending connect request to server...');
    print(connectRequest);
    _serverSock!.sink.add(connectRequest);

    //Now define the listener and configure it to block.
    //The handler method will continue the authentication handshake,
    //and will close the socket once done to return control of execution.
    await for (final msg in _serverSock!.stream) {
      _handleServerResponse(msg);
    }

    //Authentication handshake is complete.
    //First, check if we're registered.
    if (_userID == null) {
      print("Failed to register!");
      _authInProgress = false;
      return false;
    }
    //Check if we have a token.
    if ((_tokenID == null) || (_tokenSecret == null)) {
      print("Failed to obtain authentication token!");
      _authInProgress = false;
      return false;
    }

    //We have everything we need.
    //Initiate a connection to the server and return success.
    await _connect(_serverURL);
    _serverSock!.stream.listen(
      (msg) {
        _handleServerResponse(msg);
      }
    );
    _serverSock!.sink.add(_constructPingMsg(tokenAuth: true));
    print("Network is initialized and ready! :D");
    print(_userID);
    _authInProgress = false;
    return true;
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
      
      case 'AUTHENTICATE':
        _handleAuthResponse(parsedMsg);
        print("Process complete.");
        print('Token ID: ' + _tokenID!);
        print('User ID:' + _userID!);

      case 'INCOMINGMESSAGE':
        return _handleIncomingMsg(parsedMsg);
      
      case 'NEWCONVERSATIONCREATED':
        return _handleNewConvoMsg(parsedMsg);

      case 'USERLEFT':
        return _handleUserLeftMsg(parsedMsg);

    }
  }

/*
HANDLER FUNCTIONS
These are helper functions that assist the main message handler function.
Each of these handles a specific kind of message.
*/

  void _handleAuthChallenge(Map responseMsg) async {
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

  void _handleAuthResponse(Map responseMsg) async {
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
    var sink = _serverSock!.sink;
    print("We're ready to close the connection now!");
    _disconnect(true);
    print("Client should be disconnected; exiting _handleAuthResponse()...");
  }

  void _handleSearchResponse(Map responseMsg) {
    if (!_isValidSearchResponse(responseMsg)) {
      print("Network._handleSearchResponse(): Received invalid response from server!");
      responseMsg['Successful'] = false;
    }
    clientSock.sink.add(responseMsg);
  }

  void _handleIncomingMsg(Map serverMsg) {
    if (!_isValidIncomingMsg(serverMsg)) {
      print("Received incoming message but it is invalid!");
      return;
    }
    if (serverMsg['MessageType'].toString().toUpperCase() != 'TEXT') {
      serverMsg['MessageData'] = base64Decode(serverMsg['MessageData']);
    }
    clientSock.sink.add(serverMsg);
  }

  void _handleNewConvoMsg(Map serverMsg) {
    if (!_isValidNewConvoMsg(serverMsg)) {
      print("Received new conversation message but it is invalid.");
      return;
    }
    clientSock.sink.add(serverMsg);
  }

  void _handleUserLeftMsg(Map serverMsg) {
    if (!_isValidUserLeftMsg(serverMsg)) {
      print("Received user left conversation message but it is invalid.");
      return;
    }
    clientSock.sink.add(serverMsg);
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
    if (responseData['Command'].toString().toUpperCase() != 'AUTHENTICATE') return false;
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

  bool _isValidSearchResponse(Map responseData) {
    const requiredKeys = ['Command','Successful','Results'];
    for (final rkey in requiredKeys) {
      if (!responseData.containsKey(rkey)) {
        print("Required key " + rkey + " is missing!");
        return false;
      }
    }

    //Ensure the results are the right format
    if (responseData['Results'] is! List) return false;
    for (final item in responseData['Results']) {
      if (!item.containsKey('UserId') || !item.containsKey('UserName')) {
        print("Required sub-key missing from one of the response records!");
        return false;
      }
      if (item['UserId'] is! String) return false;
      if (item['UserName'] is! String) return false;
    }
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

  bool _isValidIncomingMsg(Map responseData) {
    const requiredKeys = [
      'Command',
      'OriginalReceiptTimestamp',
      'SenderId',
      'ConversationId',
      'MessageType',
      'MessageData'
      ];
    for (final rkey in requiredKeys) {
      if (!responseData.containsKey(rkey)) {
        print("Required key " + rkey + " is missing!");
        return false;
      }
      if (rkey == 'OriginalReceiptTimestamp') { //We don't want to enforce the receipt timestamp being a string
        continue;
      }

      if (responseData[rkey] is! String) {
        print("Required key " + rkey + " does not have a String value!");
        return false;
      }
    }

    //Validate message type
    const validMsgTypes = ['TEXT', 'IMAGE', 'VIDEO', 'FILE'];
    if (!(validMsgTypes.contains(responseData['MessageType'].toString().toUpperCase()))) {
      print("Invalid message type specified!");
      return false;
    }
    return true;
  }

  bool _isValidNewConvoMsg(Map responseData) {
    const requiredKeys = [
      'Command',
      'ConversationId',
      'CreatorId',
      'Members',
      ];
    for (final rkey in requiredKeys) {
      if (!responseData.containsKey(rkey)) {
        print("Required key " + rkey + " is missing!");
        return false;
      }
      if (rkey == 'Members') { //Don't check for Members to be a String value
        continue;
      }
      if (responseData[rkey] is! String) {
        print("Required key " + rkey + " does not have a String value!");
        return false;
      }
    }

    //Ensure Members is a list of strings
    if (responseData['Members'] is! List) {
      print("Members data isn't structured as a List! Aborting.");
      return false;
    }

    for (final member in responseData['Members']) {
      if (member is! String) {
        print("Detected a non-String member inside the conversationMembers list! Aborting.");
        return false;
      }
    }
    return true;
  }

  bool _isValidUserLeftMsg(Map responseData) {
    const requiredKeys = [
      'Command',
      'ConversationId',
      'LeavingUserId',
      ];
    for (final rkey in requiredKeys) {
      if (!responseData.containsKey(rkey)) {
        print("Required key " + rkey + " is missing!");
        return false;
      }
      if (responseData[rkey] is! String) {
        print("Required key " + rkey + " does not have a String value!");
        return false;
      }
    }

    return true;
  }

  //JSON server message constructors.
  //Each of these takes its requested info, and constructs
  //a valid JSON message to send directly to the server.

  String _constructPingMsg({bool tokenAuth = false}) {
    final currentTime = DateTime.timestamp();
    final pingMsg = {
      'Command':'PING',
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt(), //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (tokenAuth) {
      if ((_userID != null) && (_tokenID != null) && _tokenSecret != null) {
        pingMsg['UserId'] = _userID!;
        pingMsg['TokenId'] = _tokenID!;
        pingMsg['TokenSecret'] = base64Encode(_tokenSecret!);
      }
      else {
        throw Exception("One or more required components for authentication is missing!");
      }
    }
    const encoder = JsonEncoder();
    return encoder.convert(pingMsg);
  }

  String _constructLoginRequest(RSAPublicKey userPublicKey, String userID, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    final loginRequest = {
      'Command':'CONNECT',
      'UserPublicKeyMod': userPublicKey.modulus.toString(),
      'UserPublicKeyExp': userPublicKey.publicExponent.toString(),
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt(), //Server only accepts second-level accuracy and Dart doesn't provide that natively
      'Register': 'False',
      'UserId': userID,
    };
    if (operationID != null) {
      loginRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(loginRequest);
  }

  String _constructRegisterRequest(RSAPublicKey userPublicKey, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    final loginRequest = {
      'Command':'CONNECT',
      'UserPublicKeyMod': userPublicKey.modulus.toString(),
      'UserPublicKeyExp': userPublicKey.publicExponent.toString(),
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt(), //Server only accepts second-level accuracy and Dart doesn't provide that natively
      'Register': 'True',
      'UserId':'',
    };
    if (operationID != null) {
      loginRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(loginRequest);
  }

  String _constructAuthRequest(String challengeID, Uint8List signatureBytes, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    final connectRequest = {
      'Command':'AUTHENTICATE',
      'ChallengeId':challengeID,
      'Signature': b64.convert(signatureBytes),
      'HashAlgorithm':'SHA256',
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (operationID != null) {
      connectRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(connectRequest);
  }

  String _constructSearchUserRequest(String searchTerm, {bool searchById = false, String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    var searchBy = 'UserName';
    if (searchById) searchBy = 'UserId';
    final connectRequest = {
      'Command':'SEARCHUSERS',
      'TokenId':_tokenID,
      'TokenSecret': b64.convert(_tokenSecret!),
      'UserId':_userID,
      'SearchBy':searchBy,
      'SearchTerm':searchTerm,
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (operationID != null) {
      connectRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(connectRequest);
  }

  String _constructNewConversationRequest(List<String> recipientIDs, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    final newConversationRequest = {
      'Command':'NEWCONVERSATION',
      'TokenId':_tokenID,
      'TokenSecret': b64.convert(_tokenSecret!),
      'UserId':_userID,
      'RecipientIds':recipientIDs,
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (operationID != null) {
      newConversationRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(newConversationRequest);
  }

  String _constructLeaveConversationRequest(String conversationID, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    final leaveConversationRequest = {
      'Command':'LEAVECONVERSATION',
      'TokenId':_tokenID,
      'TokenSecret': b64.convert(_tokenSecret!),
      'UserId':_userID,
      'ConversationId':conversationID,
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (operationID != null) {
      leaveConversationRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(leaveConversationRequest);
  }

  String _constructSendTextMessageRequest(String conversationID, String msgToSend, String msgID, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    final sendMessageRequest = {
      'Command':'SENDMESSAGE',
      'TokenId':_tokenID,
      'TokenSecret': b64.convert(_tokenSecret!),
      'UserId':_userID,
      'ConversationId':conversationID,
      'MessageType':'Text',
      'MessageData':msgToSend,
      'MessageId':msgID,
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (operationID != null) {
      sendMessageRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(sendMessageRequest);
  }

  String _constructSendImageMessageRequest(String conversationID, Uint8List imageBytes, String msgID, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    final sendMessageRequest = {
      'Command':'SENDMESSAGE',
      'TokenId':_tokenID,
      'TokenSecret': b64.convert(_tokenSecret!),
      'UserId':_userID,
      'ConversationId':conversationID,
      'MessageType':'Image',
      'MessageData':b64.convert(imageBytes),
      'MessageId':msgID,
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (operationID != null) {
      sendMessageRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(sendMessageRequest);
  }

  String _constructSendVideoMessageRequest(String conversationID, Uint8List videoBytes, String msgID, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    final sendMessageRequest = {
      'Command':'SENDMESSAGE',
      'TokenId':_tokenID,
      'TokenSecret': b64.convert(_tokenSecret!),
      'UserId':_userID,
      'ConversationId':conversationID,
      'MessageType':'Video',
      'MessageData':b64.convert(videoBytes),
      'MessageId':msgID,
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (operationID != null) {
      sendMessageRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(sendMessageRequest);
  }

  String _constructSendFileMessageRequest(String conversationID, Uint8List fileBytes, String msgID, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    final sendMessageRequest = {
      'Command':'SENDMESSAGE',
      'TokenId':_tokenID,
      'TokenSecret': b64.convert(_tokenSecret!),
      'UserId':_userID,
      'ConversationId':conversationID,
      'MessageType':'Video',
      'MessageData':b64.convert(fileBytes),
      'MessageId':msgID,
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (operationID != null) {
      sendMessageRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(sendMessageRequest);
  }

  String _constructUpdateProfileRequest(String newUserName, Uint8List newProfilePic, String newStatus, String newBio, {String? operationID = null}) {
    final currentTime = DateTime.timestamp();
    const b64 = Base64Encoder();
    final updateProfileRequest = {
      'Command':'UPDATEPROFILE',
      'TokenId':_tokenID,
      'TokenSecret': b64.convert(_tokenSecret!),
      'UserId':_userID,
      'NewProfile': {
        'UserName':newUserName,
        'UserProfilePic':b64.convert(newProfilePic),
        'UserStatus':newStatus,
        'UserBio':newBio,
      },
      'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
    };
    if (operationID != null) {
      updateProfileRequest['OperationId'] = operationID;
    }
    const encoder = JsonEncoder();
    return encoder.convert(updateProfileRequest);
  }

}

//Throw this exception when a Network object is asked to perform an action that requires network connectivity, when the UI isn't listening.
class NetworkStreamListenerRequired implements Exception {
  const NetworkStreamListenerRequired(): super();
}

//Throw this exception when a Network object is asked to change critical info while connected to a server.
class ValueFrozenByNetworkConnection implements Exception {
  const ValueFrozenByNetworkConnection(): super();
}

//Throw this exception when a Network object is instructed to connect and doesn't have its RSA keypair yet.
class AuthenticationKeypairMissing implements Exception {
  const AuthenticationKeypairMissing(): super();
}

//Throw this exception when asked to perform an action that requires a non-null token.
class AuthenticationTokenMissing implements Exception {
  const AuthenticationTokenMissing(): super();
}

//Throw this exception when asked to perform an action that requires a non-null User ID.
class UserIdMissing implements Exception {
  const UserIdMissing(): super();
}