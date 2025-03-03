import hashlib
import base64
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization
import hashlib
import random

def getPubKeyBytes(pubkey: rsa.RSAPublicKey):
    return pubkey.public_bytes(encoding=serialization.Encoding.DER, format=serialization.PublicFormat.SubjectPublicKeyInfo)

def getPubKeyFromBytes(pubkeyBytes: bytes):
    return serialization.load_der_public_key(pubkeyBytes)

def verifyRSAClientSignature(*, publicKey: rsa.RSAPublicKey, signature: bytes, data: bytes):
    try:
        publicKey.verify(
            signature=signature,
            data=data,
            padding=padding.PKCS1v15(),
            algorithm=hashes.SHA256()
        )
        return True
    except:
        return False

def getSHA256(data: bytes):
    return hashlib.sha256(data).digest()

def getSHA512(data: bytes):
    return hashlib.sha512(data).digest()