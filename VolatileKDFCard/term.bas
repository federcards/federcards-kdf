Rem BasicCard Sample Source Code Template
Rem ------------------------------------------------------------------
Rem Copyright (C) 2008 ZeitControl GmbH
Rem You have a royalty-free right to use, modify, reproduce and 
Rem distribute the Sample Application Files (and/or any modified 
Rem version) in any way you find useful, provided that you agree 
Rem that ZeitControl GmbH has no warranty, obligations or liability
Rem for any Sample Application Files.
Rem ------------------------------------------------------------------
Option Explicit

#include Card.def
#Include COMMANDS.DEF
#Include COMMERR.DEF
#include MISC.DEF
#Include CARDUTIL.DEF
#include SHA.DEF
#include AES.DEF

#include string.bas
#include sha1hmac.bas
#include crypto.bas
#include session.term.bas
#include factory_key.bas






public data as string


sub checkerror()
    if SW1SW2 <> &H9000 then
        if SW1SW2 = &H8864 then
            call COMMAND_READ_ERROR(data)
            print data
        end if
        call CheckSW1SW2()
    end if
end sub

' Wait for a card
Call WaitForCard()
' Reset the card and check status code SW1SW2
ResetCard : Call CheckSW1SW2()


print str2hex(crypto_encrypt("encrypt key", "secret message"))
goto died

' A failed factory reset
data = ""
call COMMAND_FACTORY_RESET(data) : call checkerror()



if 0 then

    print "Reset auth key to <TEST AUTH KEY>"
    data = crypto_encrypt(FACTORY_KEY, "TEST AUTH KEY")
    call COMMAND_FACTORY_RESET(data) : call checkerror()
    if data = "OK" then
        print "...done"
    else
        print "...failed: " + data
        goto died
    end if

end if



public challenge as string

print "Try to answer challenge with wrong auth key"
call COMMAND_GET_CHALLENGE(challenge) : call checkerror()
if session_answer_challenge(challenge, "wrong key") <> 0 then
    print "> Error. Should be 0."
    goto died
end if
call COMMAND_GET_CHALLENGE(challenge) : call checkerror()
if session_answer_challenge(challenge, "TEST AUTH KEY") <> 1 then
    print "> Error. Should be 1."
    goto died
end if


print "Try to unlock card."
data = session_encrypt("test")
call COMMAND_UNLOCK_CARD(data) : call CheckSW1SW2()
if data <> "OK" then
    print "Failed unlocking card: " + data
    goto died
else
    print "Card unlocked."
end if



private password as string
print "Try to get a password."
data = session_encrypt("test salt")
call COMMAND_GET_PASSWORD(data) : call checkerror()
print "Command sent."
print SW1SW2
print "Encrypted response: " + str2hex(data)
password = session_decrypt(data)
print "Password = " + str2hex(password)






died:
    print "Stop."