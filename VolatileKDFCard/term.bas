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


print "Reset auth key to <TEST AUTH KEY>"
data = crypto_encrypt(FACTORY_KEY, "TEST AUTH KEY")
call COMMAND_FACTORY_RESET(data) : call checkerror()
print "...done"


public challenge as string

print "Try to answer challenge with wrong auth key"
call COMMAND_GET_CHALLENGE(challenge) : call checkerror()
print "Got challenge =", str2hex(challenge)
print "wrong, should be 0:", dec2str(session_answer_challenge(challenge, "wrong key"))
call COMMAND_GET_CHALLENGE(challenge) : call checkerror()
print "Got challenge =", str2hex(challenge)
print "right, should be 1:", dec2str(session_answer_challenge(challenge, "TEST AUTH KEY"))





died:
    print "Stop."