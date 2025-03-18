#CLIENT REQUEST FORMAT

import time
import uuid

#PING
pingMsgFormat = {
    'Command':'PING',
    'ClientTimestamp': time.time(),
}

#CONNECT TO SERVER; REQUEST NEW USER REGISTRATION
requestChallengeMsgFormat = {
    'Command':'CONNECT',
    'UserPublicKeyMod':'', #public key modulus (n); should be BigInt
    'UserPublicKeyExp':'', #public key exponent (e); should be Big int
    'UserId':'', #leave blank for registration, or fill for login
    'Register':'', #TRUE for new users, FALSE for existing users. If False, UserId must NOT be blank.
    'ClientTimestamp': time.time(),
}

#AUTHENTICATE TO SERVER (after server sends encrypted challenge)
authMsgFormat = {
    'Command':'AUTHENTICATE',
    'ChallengeId':'', #temporary UUID identifying the server-sent challenge
    'Signature':'', #signature data that can only be produced by the true user with their private key. Base64-encoded bytes.
    'HashAlgorithm':'', #Must be one of: SHA256, SHA384, SHA512. Only SHA256 is currently supported.
    'ClientTimestamp': time.time(),
}

#DISCONNECT FROM SERVER (will likely never be used in practice)
disconnectMsgFormat = {
    'Command':'DISCONNECT',
    'TokenId':'',
    'TokenSecret':'', #ephemeral token provided to 'securely' keep the session alive. Most major platforms use a token of some kind for continued auth.
    'UserId':'', #server-issued, permanent User ID. Might not be needed since the server-side DB already has the token associated with a user ID.
    'ClientTimestamp': time.time(),
}

newConversationMsgFormat = {
    'Command':'NEWCONVERSATION',
    'TokenId':'',
    'TokenSecret':'',
    'UserId':'',
    'RecipientIds':'', #comma-separated list would probably be best
    'ClientTimestamp':'',
}



sendMessageMsgFormat = {
    'Command':'SENDMESSAGE',
    'TokenId':'',
    'TokenSecret':'', #ephemeral token provided to 'securely' keep the session alive. Most major platforms use a token of some kind for continued auth.
    'UserId':'', #server-issued, permanent User ID. Might not be needed since the server-side DB already has the token associated with a user ID.
    'ConversationId':'', #server-issued Conversation ID.
    'ClientTimestamp': time.time(),
    'MessageType':'',
    'MessageData':'', #text if a text-based message; base64-encoded bytes otherwise.
}

#Not supported yet.
newConvoPolicyMsgFormat = {
    'Command':'SETPEERPOLICY',
    'TokenId':'',
    'TokenSecret':'', #ephemeral token provided to 'securely' keep the session alive. Most major platforms use a token of some kind for continued auth.
    'UserId':'', #server-issued, permanent User ID. Might not be needed since the server-side DB already has the token associated with a user ID.
    'ClientTimestamp': time.time(),
    'PeerPolicy': {
        'AllowedUsers': [],
        'AllowedKeys': [],
        'BlockedUsers': [],
        'BlockedKeys': [],
        'BcryptHash':'',
        'AllowOthers':bool, #if true, others who aren't on the allow or block lists can contact this person. If BcryptHash is non-empty, the correct password must first be specified.
        'RequireAuthForAllowListed':bool, #if true AND if BcryptHash is non-empty, those on the allowlist must still enter the correct password first.
    },
    'Profile': {
        'Name': {
            'Value': '',
            'Visibility':'',
        },
        'Photo': {
            'Value': str, #Base64-encoded data
            'Visibility':'',
        },
        'Status': {
            'Value': str,
            'Visibility':'',
        },
        'Bio': {
            'Value': str,
            'Visibility':'',
        },
    }
}


#SERVER RESPONSE FORMAT

#GENERALIZED:
generalErrorFormat = {
    'Command':'', #client-provided command
    'Successful': False,
    'ErrorType': dict,
    'RetryOperation': bool,
    'UserErrorMessage': str,
    'ClientTimestamp':'', #inherited from request
    'ServerTimestamp': time.time()
}

#Error type is one of:
errorTypes = [
    #These can happen without the client interacting with other clients.
    {'ErrorType':'BadRequest'},
    {'ErrorType':'InvalidToken'},
    {'ErrorType':'InvalidResponse'},
    {'ErrorType':'InvalidChallengeId'}, #could either be due to the challenge expiring earlier or it just not existing. Basically the same situation since the table gets pruned BEFORE querying.
    {'ErrorType':'ServerInternalError'},
    {'ErrorType':'InvalidConversationId'},
    {'ErrorType':'InvalidUserId'},
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
    'ServerTimestamp': time.time()
}

#CONNECT RESPONSE:
#Valid public key:
connectReplyFormat = {
    'Command': 'CONNECT',
    'Successful': True,
    'ChallengeRequired': True,
    'ChallengeId': str(uuid.uuid4()),
    'ChallengeData':'', #server generates random challenge bytes (base64-encoded) for client to sign
    'ClientTimestamp':'', #inherited from request
    'ServerTimestamp': time.time()
}

#AUTHENTICATE RESPONSE:
#Valid challenge response
authReplyFormat = {
    'Command': 'AUTHENTICATE',
    'Successful': True,
    'TokenId': '', #generate a random ID string for this client to use for future near-time transactions
    'TokenSecret': '', #generate a random token password for this client to use for future near-time transactions. Store the password hash but immediately destroy the raw value afterwards.
    'ClientTimestamp': '', #inherited from request
    'ServerTimestamp': time.time(),
}

#SERVER NOTIFICATIONS
incomingMessageMsgFormat = {
    'Command':'INCOMINGMESSAGE',
    'ServerTimestamp': time.time(), 
    'OriginalReceiptTimestamp':'', #timestamp of when the server received this message
    'SenderId':'', #server-issued ID for the sender.
    'MessageType':'',
    'MessageData':'',
}

newConversationCreatedMsgFormat = {
    'Command':'NEWCONVERSATIONCREATED',
    'ServerTimestamp': time.time(),
    'CreatorId':'', #server-issued ID for the user that created the conversation
    'Members':'', #server-issued User IDs for all participants in the conversation.
}