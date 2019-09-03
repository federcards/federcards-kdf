public session_tempkey as string = ""

function session_answer_challenge(challenge as string, authkey as string) as byte
    private password as string
    password = HMAC_SHA1("password" + authkey, challenge)
    print "Calc answer   =", str2hex(password)
    
    call COMMAND_START_SESSION(password)
    if password = "OK" then
        print "Session challenge passed."
        session_tempkey = HMAC_SHA1("key" + authkey, challenge)
        session_answer_challenge = 1
    else
        session_tempkey = ""
        session_answer_challenge = 0
    end if
end function


function session_encrypt(data as string) as string
    if session_tempkey = "" then
        session_encrypt = ""
        exit function
    end if
    session_encrypt = crypto_encrypt(session_tempkey, data)
end function



function session_decrypt(data as string) as string
    if session_tempkey = "" then
        session_decrypt = ""
        exit function
    end if
    session_decrypt = crypto_decrypt(session_tempkey, data)
end function