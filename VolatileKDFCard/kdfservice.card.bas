eeprom _kdf_secret_storage as string*240
const KDFSERVICE_SECRET_STORAGE_LENGTH = 48 ' 32 bytes nonce + 16 bytes AES block

public kdfservice_secretkey_memory as string



function kdfservice_readsecret() as string*KDFSERVICE_SECRET_STORAGE_LENGTH
    private i as byte
    private j as byte
    private k as byte
    private bi as integer
    private temp as byte
    private count as byte
    
    private eightbits(8) as byte
    eightbits(1) = &H01
    eightbits(2) = &H02
    eightbits(3) = &H04
    eightbits(4) = &H08
    eightbits(5) = &H10
    eightbits(6) = &H20
    eightbits(7) = &H40
    eightbits(8) = &H80
    
    for i = 1 to KDFSERVICE_SECRET_STORAGE_LENGTH
        temp = &H00
        for j = 1 to 8
            count = 0
            bi = i
            for k = 1 to 5
                if asc(_kdf_secret_storage(bi)) and eightbits(j) then
                    count = count + 1
                end if
                bi = bi + KDFSERVICE_SECRET_STORAGE_LENGTH
            next
            if count >= 3 then
                temp = temp or eightbits(j)
            end if
        next
        kdfservice_readsecret(i) = chr$(temp)
    next
end function

sub kdfservice_writesecret(s as string*KDFSERVICE_SECRET_STORAGE_LENGTH)
    _kdf_secret_storage = s + s + s + s + s
end sub


' Derive a key based on user password and a nonce, used for encrypting the
' internal storage
function kdfservice_derivekey(nonce as string, password as string) as string
    ' TODO maybe tie this with session auth key?
    kdfservice_derivekey = Sha256Hash(HMAC_SHA1(nonce, password))
end function


' Rotates the stored key by decrypting and encrypting it. Returns the decrypted
' key.
function kdfservice_rotate(password as string) as string
    private k_old as string
    private k_new as string
    private nonce_secretkey as string
    private secretkey_encrypted as string*16
    private secretkey_plain as string*16
    private nonce_old as string*32
    private nonce_new as string*32
    
    if kdfservice_secretkey_memory <> "" then
        kdfservice_rotate = kdfservice_secretkey_memory
        exit function
    end if
    
    nonce_secretkey = kdfservice_readsecret()
    
    nonce_old = Left$(nonce_secretkey, 32)
    secretkey_encrypted = Mid$(nonce_secretkey, 33, 16)
    k_old = kdfservice_derivekey(nonce_old, password)
    
    secretkey_plain = AES(-256, k_old, secretkey_encrypted)
    
    nonce_new = crypto_random32bytes()
    k_new = kdfservice_derivekey(nonce_new, password)
    secretkey_encrypted = AES(256, k_new, secretkey_plain)
    nonce_secretkey = nonce_new + secretkey_encrypted
    call kdfservice_writesecret(nonce_secretkey)
    
    kdfservice_secretkey_memory = secretkey_plain
    kdfservice_rotate = secretkey_plain
end function


' Provide KDF service: generate a pseudo-random password with given salt.
' The generated password in raw has 32 bytes(256 bits). It's up to the user, to
' convert this password into a human-friendly format.
function kdfservice(salt as string) as string
    if kdfservice_secretkey_memory = "" then
        ' Must unlock first
        kdfservice = ""
        exit function
    end if
    kdfservice = Sha256Hash(_ 
        HMAC_SHA1(kdfservice_secretkey_memory, salt + ".part1") + _ 
        HMAC_SHA1(kdfservice_secretkey_memory, salt + ".part2"))
end function


' Resets the secret key by just replacing it with random bytes. Used for factory
' reset only.
sub kdfservice_reset()
    kdfservice_writesecret(crypto_random_bytes(KDFSERVICE_SECRET_STORAGE_LENGTH))
end sub