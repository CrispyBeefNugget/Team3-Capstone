#CLIENT REQUEST FORMAT

import time
import uuid

#PING
pingMsgFormat = {
    'Command':'PING',
    'TokenId':'', #OPTIONAL. If passed then all other fields are required. The server will attempt to authenticate the user and tie their websocket to their user ID.
    'TokenSecret':'', #OPTIONAL, ephemeral token provided to 'securely' keep the session alive. Most major platforms use a token of some kind for continued auth.
    'UserId':'', #OPTIONAL, server-issued, permanent User ID. Might not be needed since the server-side DB already has the token associated with a user ID.
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

leaveConversationMsgFormat = {
    'Command':'LEAVECONVERSATION',
    'TokenId':'',
    'TokenSecret':'',
    'UserId':'',
    'ConversationId':'',
    'ClientTimestamp':'',
}

sendMessageMsgFormat = {
    'Command':'SENDMESSAGE',
    'TokenId':'',
    'TokenSecret':'', #ephemeral token provided to 'securely' keep the session alive. Most major platforms use a token of some kind for continued auth.
    'UserId':'', #server-issued, permanent User ID. Might not be needed since the server-side DB already has the token associated with a user ID.
    'ConversationId':'', #server-issued Conversation ID.
    'ClientTimestamp': time.time(),
    'MessageType':['Text', 'Image', 'Video', 'File'],
    'MessageData':'', #text if a text-based message; base64-encoded bytes otherwise.
}

searchUsersMsgFormat = {
    'Command':'SEARCHUSERS',
    'TokenId':'',
    'TokenSecret':'', #ephemeral token provided to 'securely' keep the session alive. Most major platforms use a token of some kind for continued auth.
    'UserId':'', #server-issued, permanent User ID. Might not be needed since the server-side DB already has the token associated with a user ID.
    'SearchBy':['UserId','UserName'],
    'SearchTerm':'', #
    'ClientTimestamp': time.time()
}

uploadProfileMsgFormat = {
    'Command':'UPDATEPROFILE',
    'TokenId':'',
    'TokenSecret':'', #ephemeral token provided to 'securely' keep the session alive. Most major platforms use a token of some kind for continued auth.
    'UserId':'', #server-issued, permanent User ID. Might not be needed since the server-side DB already has the token associated with a user ID.
    'NewProfile': {
        'UserName':'',
        'UserProfilePic':'',
        'UserStatus':'',
        'UserBio':'',
    },
    'ClientTimestamp': time.time(),
}

getOldMessagesMsgFormat = {
    'Command':'GETMESSAGES',
    'TokenId':'',
    'TokenSecret':'', #ephemeral token provided to 'securely' keep the session alive. Most major platforms use a token of some kind for continued auth.
    'UserId':'', #server-issued, permanent User ID. Might not be needed since the server-side DB already has the token associated with a user ID.
    'ClientTimestamp': time.time(),
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
    {'ErrorType':'InvalidRecipientId'},
    {'ErrorType':'NoRecipientsSpecified'},
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
    'AuthSuccessful': bool, #only appears if the client submitted their token info.
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
    'ConversationId':'',
    'MessageType':'',
    'MessageData':'',
}

newConversationCreatedMsgFormat = {
    'Command':'NEWCONVERSATIONCREATED',
    'ServerTimestamp': time.time(),
    'CreatorId':'', #server-issued ID for the user that created the conversation
    'Members':'', #server-issued User IDs for all participants in the conversation.
    'ConversationId':'', #server-issued Conversation ID for this conversation.
}

userLeftMsgFormat = {
    'Command':'USERLEFT',
    'LeavingUserId':'',
    'ConversationId':'',
    'ServerTimestamp':time.time(),
}

searchUsersResponseMsgFormat = {
    'Command':'SEARCHUSERS',
    'Successful': True,
    'SearchBy':['UserId','UserName'],
    'SearchTerm':'', #
    'ServerTimestamp': time.time(),
    'Results':[{'UserId':'','UserName':''}, {'UserId':'','UserName':''}]
}

uploadProfileResponseMsgFormat = {
    'Command':'UPDATEPROFILE',
    'Successful': True,
    'ServerTimestamp': time.time()
}

getOldMessagesResponseFormat = {
    'Command':'GETMESSAGES',
    'Successful': True,
    'ClientTimestamp': time.time(),
}