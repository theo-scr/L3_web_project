/***************************************
************** FONCTIONS  **************
***************************************/

// Fonction 'requeteFinPartie':
// Cette fonction est utilisée lorsque le joueur clique sur le bouton validation (il pense avoir fini) ou lorsque le temps est écoulé (la partie est finie).
// Cette fonction permet d'envoyer une requete grâce à son paramètre. L'url est différente selon la situation.
// En fonction de la réponse à cette requête, on ajuste l'action à réaliser:
function requeteFinPartie(url){
  var xhttp;
  xhttp=new XMLHttpRequest();
  test = false;
  xhttp.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      console.log('test3');
      // Si le joueur avait appuyé sur le bouton validé mais que sa figure ne correspondait pas avec l'originale, on affiche le message d'erreur pendant 4 secondes.
      if (xhttp.responseText == "perdu"){
        test = true;
        $("#message_erreur").show();
        setTimeout(function() { 
          $("#message_erreur").hide();
      }, 4000); 
      // Si le joueur avait appuyé sur le bouton validé et que sa figure correspondait avec l'originale (il a donc gagné), on le redirige vers la page 'finPartieSucces'
      } else if (xhttp.responseText == "finSucces") {
        document.location.href="/finPartieSucces";
      // Enfin, le dernier cas correspond à la fin du temps imparti, le joueur n'a pas réussi à finir sa figure (il a donc perdu), on le redirige vers la page 'finPartieEchec'
      } else {
        document.location.href="/finPartieEchec"; 
        }
    }
  };
  xhttp.open("GET", url, true);
  xhttp.send();
};

// Fonction 'secondsToMin':
// Cette fonction est utilisée par la fonction myTimer. Elle permet de convertir le temps qui est en secondes en minutes:secondes.
function secondsToMin(sec) {
  var m = Math.floor(sec % 3600 / 60)
  var s = Math.floor(sec % 3600 % 60);
  if (m < 10){
    m = '0'+m;
  }
  if (s < 10){
    s = '0'+s;
  }
return m+":"+s; 
}

// Fonction 'myTimer':
// Dès que cette fonction est appellée, elle augmente le compteur cpt et on définit le contenu HTML ayant l'identifiant 'temps' avec le temps sous le format min:sec. Elle est appelée toutes les secondes (voir ci-dessous)
// Remarque: Une requête met environ 1/2 secondes pour recevoir une réponse. Pendant ce laps ce temps, la variable dureeRealisation n'est pas définie (voir ci-dessous). Sur la console on a un essage d'erreur et le temps ne s'affiche pas pendant 4 secondes. 
// Cela n'a AUCUN impact sur la partie puisque durant les 2 premiers secondes le joueurs ne peut rien faire (il y a l'affichage de la figure à réaliser) et ensuite le temps s'affiche normalement et la partie peut se joueur. 
function myTimer() {
  cpt ++;
  $("#temps").html(secondsToMin(dureeRealisation/1000-cpt));
}


/***************************************
********* VARIABLES GLOBALES   *********
***************************************/

// La couleur par défaut est blue, c'est-à-dire que si le joueur ne sélectionne pas de couleur (grâce aux 6 boutons 'button_color') la case se colorira en blue.
var actual_color="blue";

// Pour le temps
var myVar = setInterval(myTimer, 1000);
var cpt = 0;
var test = true;

/***************************************
**************  EVENEMENTS *************
***************************************/

/*** DES LE DEBUT ***/
// Dès qu'on arrive sur la page, on cache la grille où le joueur va réaliser sa figure, on montre la grille représentation (c'est-à-dire la figure que doit réaliser le joueur) et on définit la date de début de partie.
// Une fois les 15 secondes écoulées, on fait l'inverse: on cache la grille repésentation et on montre la grille replay.
// On envoie également une requête et sa réponse nous permettra d'avoir le d'affichage de l'aide et le temps de réalisation (c'est pour cela que pendant 1/2 secondes le temps ne s'affiche pas comme en a vu ci-dessus)
// Pour finir, une fois qu'on a le temps de réalisation on peut lancer le 'setTimeout' qui une fois le temps écoulé affichera un message au joueur lui indiquant qu'il a perdu puis appelera la fonction 'requeteFinPartie' qu'on a vu si dessus.
$('#grid').hide();
$("#message_erreur").hide();
$('#repr').show();
debutPartie = new Date(); // 
var xhttp;
xhttp=new XMLHttpRequest();
url = "/partie?tempsPartie=NotNone";
xhttp.onreadystatechange = function() {
	if (this.readyState == 4 && this.status == 200) {
    // La réponse à la requête nous permet d'obtenir les temps de réalisation et d'affichage de l'aide
		reponse = xhttp.responseText;
		arrayOfReponse = reponse.split("/");
   	dureeRealisation=Number(arrayOfReponse[0]) * 1000 ;
   	dureeAffichage=Number(arrayOfReponse[1]) * 1000 ;

    // On déclenche le compte-à rebours.
		setTimeout(function () {
        //On informe le joueur qu'il a perdu
  			window.alert(" C'est finiiii ! Malheureusement, le temps est écoulé.");

        // On élabore l'url avec ses paramètres qui seront utiliser dans le fichier Python pour les insérer dans la base de donnnées
  			tempsPartie = dureeRealisation;
  			etat = "echec";
  			date = new Date();
  			var month = date.getMonth()+1;
    		var date2 = date.getDate() + "/" + month + "/" + date.getFullYear() + " " +  date.getHours() + ":" + date.getMinutes() + ":" + date.getSeconds() ;
    		url = "/partie?temps=" + tempsPartie + "&etat="+etat+"&date="+date2;

        // Appel de la fonction requeteFinPartie
    		requeteFinPartie(url);
		}
		,dureeRealisation);
   	}
};
// Envoie requête
xhttp.open("GET", url, true);
xhttp.send();

// Au bout de 15 secondes, on enlève l'affichage de la figure à réaliser et on affiche la grille permettant au joueur de réaliser sa propre figure.
setTimeout(function() { 
	$('#repr').hide();
	$('#grid').show();
}, 15000);


/*** AIDE ***/
// Quand le joueur clique sur le boutton d'aide, on cache la grille où le joueur va réaliser sa figure et on montre la grille représentation. La durée dépend de la valeur de 'dureeAffichage'.
$('#aide').click(function aide(){
	$('#grid').hide();
	$('#repr').show();	
	setTimeout(function() { 
		$('#repr').hide();
		$('#grid').show();
	 }, dureeAffichage);
});

/*** VALIDATION ***/
// Quand le joueur clique sur le boutton de validation, on doit vérifier si la figure qu'il a réalissé est identique à celle qui doit réaliser.
$('#validation').click(function(){
  // Pour comparer les deux figures, on va comprer deux chaines de caractères. Ces chaines seront consitutées des classes HTML. Pour cela, on doit les formater pour qu'on puisse les comparer. 
  // On récupère les classes HTML dans des listes
  var grilleObj = $('.grid');
  var reprObj = $('.grid2');
  
  // On crée les chaines de caractères
  var grille = ""
  var repr = ""
  for (let i=0; i< 100; i++){
  	grille = grille + grilleObj[i].className + " ";
  	repr = repr + reprObj[i].className + " ";
  }

  // On "nettoie" les chaines de caractères.
  grille = grille.replace(/ grid historique/g, "")
  repr = repr.replace(/vide/g, "rien")
  repr = repr.replace(/ grid2/g, "")

  // On peut alors les comparer. En fonction du résultat, on définit une url différente. Puis on appelle la fonction requeteFinPartie.
  if (grille == repr){
  	var finPartie = new Date();
    var tempsPartie = finPartie - debutPartie; //temps en milliseconde
    var etat = "succes";
    var month = finPartie.getMonth() + 1;
    var date = finPartie.getDate() + "/" + month + "/" + finPartie.getFullYear() + " " +  finPartie.getHours() + ":" + finPartie.getMinutes() + ":" + finPartie.getSeconds() ;
    url = "/partie?temps=" + tempsPartie + "&etat="+etat+"&date="+date;
  } else{
  	url = "/partie?temps=0&etat=echec";
  }
  requeteFinPartie(url);
});

/*** COLORATION ***/
// Pour colorier une case, le joueur clique sur une case de la grid (classe grid). On doit juste modifier la classe de la case.
$('.grid').click(function() {
  if (this.className == (actual_color+ " grid historique")){ // Si c'est la MEME couleur, on dé-colorie
    $(this).removeClass().addClass('rien grid historique');
  } 
  else { // Sinon on la colorie 
    $(this).removeClass().addClass(actual_color + ' grid historique');
  }
});

/*** HISTORIQUE ***/
// Quand le joueur clique sur une case ou un boutton, on doit l'ajouter dans la relation Historique de la base de données.
// La relation Historique a 3 attributs: action, x et y. On les obtient grâce aux identifiants et aux classes (on doit toutefois les nettoyer).
// Une fois paramètres obtenus, on envoie une requête.
$('.historique').click(function (){
  var xhttp = new XMLHttpRequest();
  var action;
  var paramCase;
  var x;
  var y;

  // On vérifie si le joueur a cliqué sur un boutton (la classe est juste "historique") ou une case (la classe est "historique grid couleur")
  if (this.className == "historique"){ // Clique sur un bouton
	  action = this.id;

	  if (action == "aide"){ // bouton Aide
		  x = -1;
		  y = 1;
	  }else{ // bouton Validation
		  x = -1;
		  y = 1;
	  }
  }
  else{ // Clique une case
    action = this.className;
    action = action.replace(/ grid historique/g, "");

    // L'identifiant des cases est tel que: 'c'+'coordonnées en x'+'cordonnées en y'
    // Comme x et y vont jusqu'à 10, il y a plusieurs cas à différencier:
  	paramCase = this.id;
  	paramCase = paramCase.replace("c", ""); // On enlève le 'c'
  	
    if (paramCase.length == 2){ // Il n'y a pas de 10 pour x ou y 
  		x=(paramCase[0]);
  		y=(paramCase[1]);
  	}
  	else if (paramCase.length == 4) { // x et y valent 10
  		x=10;
  		y=10;
  	}
  	else{ // il y a un 10 mais on doit déterminer si c'est en x ou y 
  		if (paramCase[0]=="1" && paramCase[1]=="0" ){ // c'est en x
  			x=10;
  			y=(paramCase[2]);
  		}else{ // c'est en y 
  			x=paramCase[0];
  			y=10;
  		}
  	}
  }
  // Envoie de la requête
  // Remarque: On attend pas de réponse
  url = "/partie?action=" + action + "&x="+ x + "&y="+ y;
  xhttp.open("GET", url, true);
  xhttp.send();
});


// CHANGEMENT DE COULEUR
// Lorsque le joueur clique sur une bouton ayant la classe "button_color" il change la couleur de coloriage. 
$('.button_color').click(function() {
  actual_color = this.id;
});


 // Si l'utilisateur rafraichi la page.
$(window).unload(function () {
  if (test){
    document.location.href="/finPartieQuit";
  }
});