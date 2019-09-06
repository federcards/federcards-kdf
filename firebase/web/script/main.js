var vueUsername = new Vue({
    el: "#vue-username",
    data: {
        username: "...",
    }
});

var vueCardlist = new Vue({
    el: "#vue-cardlist",
    data: {
        cards: [],
        allowDelete: false,
    },
    methods: {
        recalculateButtonAvailability: recalculateButtonAvailability,
    }
});

function recalculateButtonAvailability(){
    $('button[name="access"]').attr(
        "disabled",
        ($('#vue-cardlist').find('input[type="radio"]:checked').length != 1)
    );
}


async function onButtonAccessClicked(){
    const cardID = $('input[type="radio"]:checked').attr('data-cardid');
    const request = {
        "token": $(this).data("token"),
        "card": cardID,
        "challenge": $(this).data("challenge"),
    };
    const answer = (await firebase.functions()
            .httpsCallable("getAnswer")(request)).data;

    console.log(JSON.stringify(answer));
    var credentialdiv = $("<div>", {id: "credential"})
        .text(JSON.stringify(answer))
        .appendTo($("#response-zone").empty())
    ;
    $("#credential").attr("data-ready", "1");
}



$(async function main(){
//////////////////////////////////////////////////////////////////////////////
const app = firebase.app();
const auth = firebase.auth();
const database = firebase.database();



async function onLoggedIn(user){
    /* decide what to do:
        1. if window.location.hash contains a valid request on communication
           from Python terminal, behave as a card tempkey retriever.
        2. otherwise, behave as a server-side card manager.
    */
    $("#logged-in").show();

    // display username
    vueUsername.username = user.displayName + " <" + user.email + ">";

    // set up listener on cards list
    database.ref(user.uid + "/cards").on("value", function(snapshot){
        var val = snapshot.val() || {};
        vueCardlist.cards = [];
        for(var cardid in val){
            vueCardlist.cards.push({
                "id": cardid,
                "title": val[cardid],
            });
        }
    });

    // check if a challenge is present, switch UI
    var challenge = window.location.hash.slice(1);
    if(challenge.length == 64){ // regard as a valid challenge.
        const token = await user.getIdToken(true);
        $('button[name="access"]')
            .data('challenge', challenge)
            .data('token', token)
            .click(onButtonAccessClicked)
        ;
        $("#retrieve").show();
        $("#manage").hide();
    } else {
        $("#retrieve").hide();
        $("#manage").show();
    }
}




firebase.auth().onAuthStateChanged(async function(user){
    if(!user){
        // not logged in, or just logged out
        $("#logged-in").hide();
        const provider = new firebase.auth.GoogleAuthProvider();
        auth.signInWithRedirect(provider);
    } else {    
        // logged in
        await onLoggedIn(user);
    }
});



//////////////////////////////////////////////////////////////////////////////
});
