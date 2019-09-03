const admin = require('firebase-admin');
const functions = require('firebase-functions');
const firebaseApp = admin.initializeApp();
const auth = admin.auth();
const dbRoot = admin.database().ref();
const crypto = require("crypto");

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

exports.getAnswer = functions.https.onRequest(async (request, response) => {
    const token = request.body.token, 
          card = request.body.card,
          challenge = request.body.challenge;

    var uid, bufChallenge, authkey;

    try{
    
        if (!(
            typeof card == "string" &&
            typeof token == "string" &&
            typeof challenge == "string"
        ))
            throw Exception();

        bufChallenge = new Buffer.from(challenge, "hex");
        if (bufChallenge.length != 32) throw Exception();
    } catch(e){
        return response.status(400).send("Invalid input.");
    }

    try {
        const decodedToken = await auth.verifyIdToken(token);
        uid = decodedToken.uid;
    } catch(e){
        response.status(401).send("Access denied :(");
        return;
    }

    try{
        const keypath = dbRoot.child(uid).child("keys").child(card);
        authkey = await keypath.once("value");
        if(authkey === null) throw Exception();
    } catch(e){
        return response.status(404).send("This card is not registered.")
    }

    const passwordHMAC = crypto.createHmac('sha1', 'password' + authkey),
          keyHMAC = crypto.createHmac('sha1', 'key' + authkey);

    const password = passwordHMAC.update(bufChallenge).digest('hex'),
          tempkey  = keyHMAC.update(bufChallenge).digest('hex');

    response.status(200).send({
        "password": password,
        "tempkey": tempkey,
    });
});
