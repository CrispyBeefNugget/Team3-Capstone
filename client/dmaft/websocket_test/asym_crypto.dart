/*
CREDIT: https://github.com/bcgit/pc-dart/blob/master/tutorials/rsa.md
This is mostly boilerplate code from that side so far.
Luckily, it accomplishes everything we need.
I'll develop this further to produce RSA keys and signatures
required for server authentication.
*/

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import "package:pointycastle/export.dart";

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 2048}) {
  // Create an RSA key generator and initialize it

  // final keyGen = KeyGenerator('RSA'); // Get using registry
  final keyGen = RSAKeyGenerator();

  keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      secureRandom));

  // Use the generator
  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types
  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}


//Pass this method to generateRSAkeyPair as one of its arguments.
SecureRandom exampleSecureRandom() {

  final secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(
        Platform.instance.platformEntropySource().getBytes(32)));
  return secureRandom;
}


//Sign some data given an RSA private key.
//This method uses SHA256 to produce the signature hash.
Uint8List rsaSign(RSAPrivateKey privateKey, Uint8List dataToSign) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');

  // initialize with true, which means sign
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  final sig = signer.generateSignature(dataToSign);
  return sig.bytes;
}


//Verify an RSA private key signature given the public key, data, and the signature.
//This method assumes that the signature hash was made using SHA256.
bool rsaVerify(
    RSAPublicKey publicKey, Uint8List signedData, Uint8List signature) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final sig = RSASignature(signature);

  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');

  // initialize with false, which means verify
  verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

  try {
    return verifier.verifySignature(signedData, sig);
  } on ArgumentError {
	return false; // for Pointy Castle 1.0.2 when signature has been modified
  }
}

void testAuth() {
  final pair = generateRSAkeyPair(exampleSecureRandom());
  final public = pair.publicKey;
  final private = pair.privateKey;

  String testStr = "Hello there!";
  Uint8List data = Utf8Encoder().convert(testStr);
  final mySignature = rsaSign(private, data);
  print(mySignature);
  bool result = rsaVerify(public, data, mySignature);
  print(result);
}

