#!/usr/bin/env python3

from smartcard.ATR import ATR
from smartcard.CardType import ATRCardType
from smartcard.CardRequest import CardRequest
from .crypto import crypto_encrypt, crypto_decrypt

"""
declare command &H88 &H64 COMMAND_READ_ERROR(data as string)
declare command &H88 &H00 COMMAND_FACTORY_RESET(data as string)
declare command &H88 &H02 COMMAND_GET_CHALLENGE(data as string)
declare command &H88 &H04 COMMAND_START_SESSION(data as string)
declare command &H88 &H06 COMMAND_UNLOCK_CARD(data as string)
declare command &H88 &H08 COMMAND_GET_PASSWORD(data as string)
"""


class CardIOError(IOError):

    def __init__(self, sw1, sw2, data):
        IOError.__init__(self, data)
        self.sw1 = sw1
        self.sw2 = sw2
        self.sw1sw2 = (sw1 << 8) | sw2
        self.data = data



class CardIO:

    def __init__(self):
        self.cardRequest = CardRequest(timeout=10) #, cardType=cardtype)
        self.__key = None

    def __sendCommandRaw(self, CLA, INS, data=b''):
        assert type(data) == bytes
        
        data = list(data)
        # See ISO7816-3. APDU begins with CLA, INS, P1, P2 and ends with
        # an expected count of response bytes. If there's data to send,
        # after the 4-bytes header there's a count of request bytes followed
        # by actual data. Otherwise, both are skipped.
        # In our case, CLA and INS are arguments, P1=P2=0, and always expecting
        # maximum response size(0xFE=254 bytes).
        if data:
            apdu = [CLA, INS, 0x00, 0x00, len(data)] + data + [0xFE]
        else:
            apdu = [CLA, INS, 0x00, 0x00, 0xFE]

        response, sw1, sw2 = self.cardService.connection.transmit(apdu)
        response = bytes(response)

        if not ((sw1 == 0x90 and sw2 == 0x00) or sw1 == 0x61):
            if sw1 == 0x88 and sw2 == 0x64:
                response, _, __ = self.cardService.connection.transmit(
                    [0x88, 0x64, 0x00, 0x00, 0xFE])
                response = bytes(response)
            raise CardIOError(sw1=sw1, sw2=sw2, data=response)

        return sw1, sw2, response

    def factoryReset(self, request):
        sw1, sw2, data = self.__sendCommandRaw(0x88, 0x00, request)
        return (sw1, sw2, data)

    def getChallenge(self):
        sw1, sw2, data = self.__sendCommandRaw(0x88, 0x02)
        return data

    def startSession(self, password, key):
        sw1, sw2, data = self.__sendCommandRaw(0x88, 0x04, password)
        if data == b"OK":
            self.__key = key
        else:
            self.__key = None
        return (sw1, sw2, data)

    def unlockCard(self, password):
        if not self.__key:
            raise Exception("Session not started.")
        encryptedPassword = crypto_encrypt(self.__key, password)
        sw1, sw2, data = self.__sendCommandRaw(0x88, 0x06, encryptedPassword)
        return sw1, sw2, data

    def getPassword(self, salt):
        if not self.__key:
            raise Exception("Session not started.")
        encryptedSalt = crypto_encrypt(self.__key, salt)
        sw1, sw2, encryptedPassword = self.__sendCommandRaw(
            0x88, 0x08, encryptedSalt)
        password = crypto_decrypt(self.__key, encryptedPassword)
        return password

    def __enter__(self, *args, **kvargs):
        self.cardService = self.cardRequest.waitforcard()

        self.cardService.connection.connect()
        atr = ATR(self.cardService.connection.getATR())
        identification = bytes(atr.getHistoricalBytes())

        if identification != b"feder.cards/pg1":
            raise Exception("Wrong card inserted.")
        return self
            

    def __exit__(self, *args, **kvargs):
        pass
