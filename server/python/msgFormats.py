#CLIENT REQUEST FORMAT

import time
import uuid

#PING
pingMsgFormat = {
    'Command':'PING',
    'ClientTimestamp': time.gmtime(),
}

#CONNECT TO SERVER (SIGN UP OR LOG IN)
connectMsgFormat = {
    'Command':'CONNECT',
    'UserPublicKey':'', #public key data here in bytes
    'ClientTimestamp': time.gmtime(),
}

#AUTHENTICATE TO SERVER (after server sends encrypted challenge)
authMsgFormat = {
    'Command':'AUTHENTICATE',
    'ChallengeId':'', #temporary UUID identifying the server-sent challenge
    'Response':'', #signature data that can only be produced by the true user with their private key
    'ClientTimestamp': time.gmtime(),
}

#DISCONNECT FROM SERVER (will likely never be used in practice)
disconnectMsgFormat = {
    'Command':'DISCONNECT',
    'UserPublicKey':'',
    'Token':'', #ephemeral token provided to 'securely' keep the session alive. Most major platforms use a token of some kind for continued auth.
    'ClientTimestamp': time.gmtime(),
}



#SERVER RESPONSE FORMAT

#GENERALIZED:
generalErrorFormat = {
    'Command':'', #client-provided command
    'Successful': False,
    'ErrorType': dict,
    'UserErrorMessage': str,
    'ClientTimestamp':'', #inherited from request
    'ServerTimestamp': time.gmtime()
}

#Error type is one of:
errorTypes = [
    #These can happen without the client interacting with other clients.
    {'ErrorType':'BadRequest'},
    {'ErrorType':'InvalidToken'},
    {'ErrorType':'InvalidResponse'},
    {'ErrorType':'ChallengeExpired'}, #failed auth only
    {'ErrorType':'ServerInternalError'},
    {'ErrorType':'InvalidConversationId'},
    {
        'ErrorType':'UserBanned',
        'BanExpiry': time, #Cannot be non-None unless PermanentBan is False
        'PermanentBan': bool, #Cannot be True unless BanExpiry is None
    },
]

#PING:
pingReplyFormat = {
    'Command': 'PING',
    'Successful': True,
    'ClientTimestamp':'', #inherited from request
    'ServerTimestamp': time.gmtime()
}

#CONNECT RESPONSE:
#Valid public key:
connectReplyFormat = {
    'Command': 'CONNECT',
    'Successful': True,
    'ChallengeRequired': True,
    'ChallengeId': uuid.uuid4(),
    'ChallengeData':'', #server generates random challenge string for client to decrypt & sign; encrypts using user's public key
    'ClientTimestamp':'', #inherited from request
    'ServerTimestamp': time.gmtime()
}

#AUTHENTICATE RESPONSE:
#Valid challenge response
authReplyFormat = {
    'Command': 'AUTHENTICATE',
    'Successful': True,
    'TokenId': '', #generate a random ID string for this client to use for future near-time transactions
    'Token': '', #generate a random token password for this client to use for future near-time transactions. Store the password hash but immediately destroy the raw value afterwards.
    'ClientTimestamp': '', #inherited from request
    'ServerTimestamp': time.gmtime()
}
