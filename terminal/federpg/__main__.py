#!/usr/bin/env python3

DEBUG = True 

import argparse
import os
import re
import json
from getpass import getpass
from .cardio import CardIO
from .kiosk import getCredential
from .crypto import crypto_encrypt, crypto_decrypt


parser = argparse.ArgumentParser()

group = parser.add_mutually_exclusive_group(required=True)
group.add_argument(
    "--factory", type=str,
    metavar="/PATH/TO/factory_key.bas",
    help="""Factory reset the card. Must specify <factory_key.bas>.
    By default, a random authentication key will be written to card and
    printed to output. You may custom this key via --auth-key option.""")
group.add_argument(
    "--access", action="store_true",
    help="Access the card."""
)

parser.add_argument("--auth-key", type=str,
    help="""Set the authentication key in HEX. If --factory is in effect, this
    will be the new authentication key written to card. If --access is in
    effect, this will be the authentication key used to access the card, and
    a login process will be skipped.""")

args = parser.parse_args()



if args.factory:
    if os.path.basename(args.factory) != "factory_key.bas":
        print("Must provide a <factory_key.bas>")
        exit(1)
    factoryKey = re.search("[0-9a-f]{64}", open(args.factory, "r").read())
    if not factoryKey:
        print("Factory key file invalid.")
        exit(1)
    factoryKey = bytes.fromhex(factoryKey[0])
    if args.auth_key:
        authKey = bytes.fromhex(args.auth_key)
    else:
        authKey = os.urandom(32)

    with CardIO() as cio:
        print(cio.factoryReset(crypto_encrypt(factoryKey, authKey)))
        exit()

elif args.access:

    #try:
    with CardIO() as cio:
        challenge = cio.getChallenge()

        if not args.auth_key:
            credential = getCredential(challenge=challenge.hex())
        else:
            import hashlib
            import hmac
            authKey = bytes.fromhex(args.auth_key)

            password = hmac.HMAC(
                b"password" + authKey,
                challenge,
                hashlib.sha1).hexdigest()
            tempkey = hmac.HMAC(
                b"key" + authKey,
                challenge,
                hashlib.sha1).hexdigest()
            
            credential = """{"password": "%s", "tempkey": "%s"}""" % (
                password, tempkey)

        credential = json.loads(credential)
        print(cio.startSession(
            bytes.fromhex(credential["password"]),
            bytes.fromhex(credential["tempkey"])
        ))

        print("-" * 40)
        print("Ready to unlock the card. Caution: password must be correct!")
            
        while True:
            password1 = getpass("Input password    :")
            password2 = getpass("Repeat to confirm :")
            if password1 == password2:
                break
            print("Password not match. Please check again.")

        print("Decrypting smart card...")
        print(cio.unlockCard(password1.encode("ascii")))

        print("Test get a password.")
        print(cio.getPassword(b"test"))





    #except Exception as e:
    #    print(e)
    #    exit()
        
