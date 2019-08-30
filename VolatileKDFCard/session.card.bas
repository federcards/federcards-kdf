' Session manager for smartcard
'
' This is the underlying structure for communicating with this smartcard. It
' does following tasks:
'   1. Authentication and negotiation of a session key.
'   2. Communication encrypted by the session key.
'   3. Accepting the replacement of a new authentication key.

eeprom session_authkey as string

public session_challenge as string
public session_password as string
public session_tempkey as string


' Accepts the request for replacing `session_authkey`
' `request` is a string encrypted by factory key.
function session_replace_authkey(request as string) as byte
    
    private newkey as string
    newkey = crypto_decrypt(FACTORY_KEY, request)
    if newkey = "" then
        session_replace_authkey = 0
    else
        session_authkey = newkey
        session_replace_authkey = 1
    end if
end function


' Returns 1 if session is started
' (session tempkey generated and challenge removed).
function session_is_started() as byte
    if session_tempkey <> "" and session_challenge = "" then
        session_is_started = 1
    else
        session_is_started = 0
    end if
end function


' Starts a session if not already started. Returns session_challenge.
function session_get_challenge() as string
    if session_challenge = "" then
        ' First time start. Generates a challenge.
        session_challenge = crypto_random32bytes()
        session_password = HMAC_SHA1(_
            "password" + session_authkey, session_challenge)
        session_tempkey  = HMAC_SHA1("key" + session_authkey, session_challenge)
    end if
    session_get_challenge = session_challenge
end function


' Verifies a challenge
function session_start(password as string) as byte
    if password <> session_challenge then
        session_start = 0
        exit function
    end if
    session_challenge = ""
    session_password = ""
    session_start = 1
end function


' Communcation handling: encryption and decryption

function session_encrypt(data as string) as string
    if 0 = session_is_started() then
        session_encrypt = ""
        exit function
    end if
    session_encrypt = crypto_encrypt(session_tempkey, data)
end function

function session_decrypt(data as string) as string
    if 0 = session_is_started() then
        session_decrypt = ""
        exit function
    end if
    session_decrypt = crypto_decrypt(session_tempkey, data)
end function