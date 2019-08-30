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

#include AES.DEF
#include SHA.DEF
#include sha1hmac.bas
#include crypto.bas
#include factory_key.bas
#include session.card.bas

#IfDef MultiAppBasicCard
  ' This section is required for MultiApplication BasicCards only
  ' it is ignored for Enhanced and Professional BasicCards
  #Include COMPONNT.DEF
  Dir "\"
    Application "DefaultApp" ' Make this the Default Application
      Lock=Execute:Always
  End Dir
#EndIf

' This variable is of storage type EEPROM
' and thus persistent
EEPROM CardData as String

' This command just returns "Hello World" in response
' Since no input data is required, LC is set to 0
Command &H88 &H00 HelloWorld(LC=0, Data as String)
   Data=HMAC_SHA1("Jefe", "what do ya want for nothing?")
End Command

' This command saves Data in EEPROM.
' Since no output data is required, LE is disabled
Command &H88 &H02 WriteData(Data as String, Disable LE)
   ' Just copy it to EEPROM variable to save it
   CardData=Data
End Command

' This command reads data written by WriteData and 
' returns this data in response.
' Since no input data is required, LC is set to 0
Command &H88 &H04 ReadData(LC=0, Data as String)
   Data=CardData
End Command