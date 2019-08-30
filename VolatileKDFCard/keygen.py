#!/usr/bin/env python3

import os

FILENAME = "factory_key.bas"

if os.path.isfile(FILENAME):
    print("File `%s` exists. Abort.\n" % FILENAME)
    print("This usually means you've got a factory key already.\nIf you are "
        "sure to generate a new factory key, remove that file.\nRemember to "
        "backup!")
    exit()

rnd = os.urandom(32)
output = """
' This is the factory key used for setting up this card. You should not change
' this file manually. Instead, run `python3 keygen.py` to get a new key.

' The factory key is: %s

const FACTORY_KEY = chr$(%s)
""" % (
    rnd.hex(),
    ",".join([str(int(e)) for e in rnd])
)

open(FILENAME, "w+").write(output)
