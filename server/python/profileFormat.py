profileFormat = {
    'userID':'', #server-issued UUID for the user. Text.
    'userName':'', #user-set nickname. Text.
    'userBio':'', #user-set bio. Text.
    'userStatus':'', #this might not exist. Text.
    'userPic':'', #user-set profile picture. Base64-encoded bytes for network transmission.
    'lastUpdated':'', #last time this was updated. Probably UNIX epoch seconds for network transmission, could be different in client DB.
}