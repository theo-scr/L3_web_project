/***************************************
************** FONCTIONS  **************
***************************************/

// Fonction 'play':
// On appelle la fonction action en passant le paramètre cpt. Une fois la fonction action appellée on incrémente le compteur cpt. Au début le compteur vaut 0 (on appelle la fonction play quand le joueur clique sur le bouton 'play' pour la première fois)
function play () { 
  action(cpt);
  cpt++;
}

// Fonction 'action':
// Cette fonction permet d'envoyer une requête. Elle contient le paramètre cpt.
// En fonction de la réponse, soit c'est la fin du replay et on se dirige vers la page '/finReplay', soit il reste encore des actions dans ce cas on appelle la fonction historique en lui passant en paramètres la réponse à la requête.
function action(cpt){
  var xhttp = new XMLHttpRequest();

  url = "/replay?cpt="+cpt;

  xhttp.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      reponse = xhttp.responseText;
      if(xhttp.responseText == "finReplay"){
        clearInterval(myVar);
        document.location.href="/finReplay";
      }else{
        arrayOfReponse = reponse.split("/");

        act=arrayOfReponse[0];
        couleur=arrayOfReponse[1];
        x=arrayOfReponse[2];
        y=arrayOfReponse[3];
        
        historique(act, couleur, x, y);
      } 
    }
  };

  xhttp.open("GET", url, true);
  xhttp.send();
}

// Fonction 'historique':
// Comme vu précédemment, la réponse à la reqûete envoyé grâce à la fonction action nous permet d'avoir la nouvelle action que le joueur avait réalisé. 
// Ainsi en fonction du type d'action, on colorie une case, on décolore une case ou on affiche un message
function historique (action, couleur, x, y){
  if (action == 7){
    $("#message_aide").show();
    setTimeout(function() { 
      $("#message_aide").hide();
    }, 2000); 
  }
  else if (action ==8){
    $("#message_erreur").show();
    setTimeout(function() { 
      $("#message_erreur").hide();
    }, 2000); 
  }
  else if (action ==9){
    $('#c'+x+y).removeClass().addClass('rien grid historique');
  }
  else{
    $('#c'+x+y).removeClass().addClass(couleur + ' grid historique');
  }
}

/***************************************
**************  EVENEMENTS *************
***************************************/

// Dès qu'on arrive sur la page, on cache la grille où va se faire le replay et on montre la grille représentation (c'est_à-dire la figure que devais réaliser le joueur)
// Une fois les 10 secondes écoulées, on fait l'inverse: on cache la grille repésentation et on montre la grille replay.
$('#repr').show();
$('#message_repr').show();
$("#message_erreur").hide();
$("#message_aide").hide();
$('#grid').hide();
setTimeout(function() { 
  $('#repr').hide();
  $('#message_repr').hide();
  $('#grid').show();
  debutPartie = new Date();
}, 10000);


// Quand le joueur clique sur le bouton Play (ayant l'identifiant 'play') cela signifie qu'il lance le replay. On désactive alors le bouton et on appelle alors la fonction 'play'.
$('#play').click(function() {
  $("#play").attr("disabled", "");
  cpt=0;
  finReplay = false;
  myVar = setInterval(play , 2000);
});