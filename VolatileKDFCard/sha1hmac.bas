' ******************************************************************************
' This file defines function
'  HMAC_SHA1(strKey, strMessage) as String
' which calculates a SHA1 based HMAC for given message.
' ******************************************************************************


const SHA1HMAC_BLOCK_SIZE = 64
const SHA1HMAC_OUTPUT_SIZE = 20
const SHA1HMAC_ALLZERO = chr$(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

public SHA1HMAC_OPADBUFFER as string*64
public SHA1HMAC_IPADBUFFER as string*64
public SHA1HMAC_KEYBUFFER as string*64



Sub SHA1HMAC_XOR_WITH_BYTE(byref destBuffer as string, byref srcBuffer as string, byteWith as Byte)
    private i as Integer
    for i = 1 to SHA1HMAC_BLOCK_SIZE
        destBuffer(i) = chr$(asc(srcBuffer(i)) xor byteWith)
    next
End Sub


Function HMAC_SHA1(strKey as String, strMessage as String) as String
    Left$(SHA1HMAC_KEYBUFFER, SHA1HMAC_BLOCK_SIZE) = SHA1HMAC_ALLZERO

    if len(strKey) > SHA1HMAC_BLOCK_SIZE then
        Left$(SHA1HMAC_KEYBUFFER, SHA1HMAC_BLOCK_SIZE) = ShaHash(strKey)
    else
        Left$(SHA1HMAC_KEYBUFFER, SHA1HMAC_BLOCK_SIZE) = strKey
    end if
    
    call SHA1HMAC_XOR_WITH_BYTE(SHA1HMAC_IPADBUFFER, SHA1HMAC_KEYBUFFER, &H36)
    call SHA1HMAC_XOR_WITH_BYTE(SHA1HMAC_OPADBUFFER, SHA1HMAC_KEYBUFFER, &H5C)
    
    
    HMAC_SHA1 = ShaHash(SHA1HMAC_OPADBUFFER + ShaHash(SHA1HMAC_IPADBUFFER + strMessage))
    
    Left$(SHA1HMAC_KEYBUFFER, SHA1HMAC_BLOCK_SIZE) = SHA1HMAC_ALLZERO
    Left$(SHA1HMAC_IPADBUFFER, SHA1HMAC_BLOCK_SIZE) = SHA1HMAC_ALLZERO
    Left$(SHA1HMAC_OPADBUFFER, SHA1HMAC_BLOCK_SIZE) = SHA1HMAC_ALLZERO
End Function