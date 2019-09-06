const admin = require('firebase-admin');
const functions = require('firebase-functions');
const firebaseApp = admin.initializeApp();
const auth = admin.auth();
const dbRoot = admin.database().ref();
const crypto = require("crypto");


exports.getAnswer = functions.https.onCall(async (data, context) => {
    const uid = context.auth.uid,
          challenge = data.challenge,
          card = data.card;

    var bufChallenge, authkey;

    try{
    
        if (!(
            typeof card == "string" &&
            typeof challenge == "string"
        ))
            throw Exception();

        bufChallenge = new Buffer.from(challenge, "hex");
        if (bufChallenge.length != 32) throw Exception();
    } catch(e){
        return {"error": "Invalid input."}
    }

    try{
        const keypath = dbRoot.child(uid).child("keys").child(card);
        authkey = (await keypath.once("value")).val();
        if(authkey === null) throw Exception();
        authkey = Buffer.from(authkey, "hex");
    } catch(e){
        return {"error": "This card is not properly registered."};
    }

    const k1 = Buffer.concat([
        Buffer.from("password"),
        authkey
    ]);
    const k2 = Buffer.concat([
        Buffer.from("key"),
        authkey
    ]);

    const passwordHMAC = crypto.createHmac('sha1', k1),
          keyHMAC = crypto.createHmac('sha1', k2);

    const password = passwordHMAC.update(bufChallenge).digest('hex'),
          tempkey  = keyHMAC.update(bufChallenge).digest('hex');

    return {
        "password": password,
        "tempkey": tempkey,
    };
});
