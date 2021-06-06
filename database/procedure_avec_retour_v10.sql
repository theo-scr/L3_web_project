/*
Script permettant de créer les sept procédures de notre base de données. 
Nous avons laissé les "DMBS_OUT" en commentaire pour savoir le type d'erreur associé au code retour (même si dans le rapport nous avons égalemment détaillé à quoi correspondent ces retours). 
Ils nous servent également de commentaires.
*/

set serveroutput on;

/*
Procédure 'inserer_figure', utilisée pour insérer une figure dans la base de données et vérifier les erreurs éventuelles
Entrées : vCasesColoriees -> nombre de cases coloriées
		  vnbCouleurs -> nombre de couleurs différentes constituant la figure
		  vNiveau -> niveau de la figure
Sortie : retour -> code de retour qui sera traité dans le code Python
*/
create or replace procedure inserer_figure (vCasesColoriees IN Figure.nbCasesColoriees%type, vnbCouleurs IN Figure.nbCouleursFigure%type, vNiveau IN Figure.niveauFigure%type, retour OUT number) as
    pbCheck exception;
    pragma exception_init(pbCheck,-2290);
    pbNiveau exception;
    pragma exception_init(pbNiveau,-2291);
	
BEGIN

    insert into Figure values (SEQ_FIGURE.nextval, vCasesColoriees, vnbCouleurs, vNiveau);
    commit;
    retour:=0;
	
EXCEPTION
	-- Erreur qui ne doit jamais arriver vu qu'on utilise une séquence.
	When DUP_VAL_ON_INDEX Then
        retour:=1;
        --DBMS_OUTPUT.PUT_LINE('Duplication clé primaire - Cet identifiant de figure existe déjà dans la base.');
	
	-- Erreur de clé étrangère    
	When pbNiveau Then
        retour:=15;
        --DBMS_OUTPUT.PUT_LINE('Clé étrangère inexistante - Le niveau de la figure n existe pas.');
   
	-- Erreurs liées aux contraintes CHECK
	When pbCheck Then
        if (SQLERRM like '%CH_NBCASESCOLORIEES%') then
            retour:=21;
            --DBMS_OUTPUT.PUT_LINE('Le nombre de cases coloriées doit être entre 1 et 100.');
        elsif (SQLERRM like '%CH_NBCOULEURSFIGURE%') then
            retour:=22;
            --DBMS_OUTPUT.PUT_LINE('Le nombre de couleurs doit être entre 1 et 6.');
        elsif (SQLERRM like '%NN_NBCASESCOLORIEES%') then
            retour:=31;
            --DBMS_OUTPUT.PUT_LINE('Le nombre de cases coloriées est Null (il doit être entre 1 et 100).');
        elsif (SQLERRM like '%NN_NBCOULEURSFIGURE%') then
            retour:=32;
            --DBMS_OUTPUT.PUT_LINE('Le nombre de couleurs est Null (il doit être entre 1 et 6).');
        elsif (SQLERRM like '%NN_NIVEAUFIGURE%') then
            retour:=33;
            --DBMS_OUTPUT.PUT_LINE('Le niveau de la figure est Null.');
        else 
            retour:=SQLCODE;
            --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
        end if;
	
	-- Autres erreurs    
	When Others Then
        retour:=SQLCODE;
        --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
END;
/


/*
Procédure 'inserer_joueur', utilisée pour insérer un joueur dans la base de données et vérifier les erreurs éventuelles
Entrées : vJoueur -> identifiant que le joueur a rentré
		  vMotPasse -> mot de passe que le joueur a rentré 
Sortie : retour -> code de retour qui sera traité dans le code Python
*/
create or replace procedure inserer_joueur (vJoueur IN Joueur.idJoueur%type,vMotPasse IN Joueur.motPasse%type,retour OUT number) is
    mdpNull exception;
    pragma exception_init(mdpNull, -2290);
    idNull exception;
    pragma exception_init(idNull, -1400);
    longueur exception;
    pragma exception_init(longueur, -12899);
	
BEGIN

    insert into Joueur values (vJoueur,vMotPasse,1, null); -- Par défault, lorsqu'on crée un joueur son niveau maximal est à 1.
    commit;
    retour:=0;  
	
EXCEPTION
	-- Erreur de clé primaire
    When DUP_VAL_ON_INDEX Then
        retour:=1;
        --DBMS_OUTPUT.PUT_LINE('Duplication clé primaire - Cet identifiant de joueur existe déjà dans la base.');
    
	-- Erreurs liées à la longueur de chaînes de caractères (20 caractères maximum car on a définit VARCHAR(20))
	When longueur Then
        if (SQLERRM like '%IDJOUEUR%') then
            retour:=23;
            --DBMS_OUTPUT.PUT_LINE('L''identifiant est trop long (plus de 20 caractères)');
        elsif (SQLERRM like '%MOTPASSE%') then
            retour:=24;
            --DBMS_OUTPUT.PUT_LINE('Le mot de passe est trop long (plus de 20 caractères)');
        else 
            retour:=SQLCODE;
			--DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
        end if;
	
	-- Clé primaire Null
    When idNull Then
        retour:=34;
        --DBMS_OUTPUT.PUT_LINE('L identifiant de joueur ne peut etre null');

	-- Erreur liée au CHECK     
	When mdpNull Then 
        if (SQLERRM like '%NN_MOTPASSE%') then
            retour:=35;
            --DBMS_OUTPUT.PUT_LINE('Le mot de passe ne doit pas etre null');
        else 
            retour:=SQLCODE;
            --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
        end if;

	-- Autres erreurs
    When Others Then
        retour:=SQLCODE;
        --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
END;
/


/*
Procédure 'update_joueur', utilisée pour mettre à jour le niveau et/ou la date de blocage et vérifier les erreurs éventuelles (pour le mot de passe c'est possible avec cette procédure, mais on ne donnera pas cette possibilité au joueur dans notre site).
Entrées : vJoueur ->  identifiant du joueur connecté 
		  vMotPasse -> nouveau mot de passe du joueur connecté (évidemment peut-être le même que l'ancien)
		  vNiveau -> nouveau niveau maximal débloqué par le joueur connecté
		  vDateBlocage -> nouvelle date de blocage éventuelle pour le joueur connecté
Sortie : retour -> code de retour qui sera traité dans le code Python
*/
create or replace procedure update_joueur (vJoueur IN Joueur.idJoueur%type,vMotPasse IN Joueur.motPasse%type, 
vNiveau IN Joueur.niveauMax%type, vDateBlocage IN Joueur.dateBlocage%type,retour OUT number) is
    incremBy1 exception;
    pragma exception_init(incremBy1,-20003);
    pasDebloque exception;
    pragma exception_init(pasDebloque,-20004);
    longueur exception;
    pragma exception_init(longueur,-12899);
    pbCheck exception;
    pragma exception_init(pbCheck,-2290);
    niveauMax4 exception;
    pragma exception_init(niveauMax4,-2291);
	
BEGIN 
	-- On met à jour les informations du joueur 'vJoueur'
    update Joueur
    set motPasse = vMotPasse, niveauMax = vNiveau, dateBlocage=vDateBlocage
    where idJoueur=vJoueur;
    commit;
    retour:=0;
	
EXCEPTION
	-- Erreurs liées à la longueur de chaînes de caractères (20 caractères maximum car on a définit VARCHAR(20))
	When longueur Then
        if (SQLERRM like '%MOTPASSE%') then
            retour:=24;
            --DBMS_OUTPUT.PUT_LINE('Le mot de passe est trop long (plus de 19 caractères)');
        else 
            retour:=SQLCODE;
			--DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
        end if;
	
	-- Erreur liée à la clé étrangère 'niveauMax'
    When niveauMax4 Then
        retour:=25;
        --DBMS_OUTPUT.PUT_LINE('Le niveau doit être entre 1 et 4');

	-- Erreurs liées aux contraintes CHECK
    When pbCheck Then
        if (SQLERRM like '%NIVEAUMAX%') then
            retour:=33;
            --DBMS_OUTPUT.PUT_LINE('Le niveau est null');
        elsif (SQLERRM like '%MOTPASSE%') then
            retour:=35;
            --DBMS_OUTPUT.PUT_LINE('Le mot de passe est null');
        else 
            retour:=SQLCODE;
			--DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
        end if;

	-- Erreur n°1 du trigger t_a_u_Joueur
    When incremBy1 Then
        retour:=41;
        --DBMS_OUTPUT.PUT_LINE('On peut seulement augmenter le niveau d''un cran');

	-- Erreur n°2 du trigger t_a_u_Joueur
    When pasDebloque Then
        retour:=42;
        --DBMS_OUTPUT.PUT_LINE('Le joueur n''a pas réussi toutes les figures du niveau précédent pour pouvoir augmenter de niveau');

	-- Autres erreurs
    When Others Then
        retour:=SQLCODE;
        --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
END;
/
 
/*
Procédure 'inserer_partie' utilisée pour insérer une partie dans la base de données et vérifier les erreurs éventuelles
Entrées : vJoueur -> identifiant du joueur connecté 
		  vFigure -> identifiant de la figure qu'on lui a attribué après qu'il est choisi son niveau
Sortie : retour -> code de retour qui sera traité dans le code Python
*/
create or replace procedure inserer_partie (vJoueur IN Partie.joueurPartie%type, vFigure IN Partie.figurePartie%type,retour OUT number) is
    blocageNiveau exception;
    pragma exception_init(blocageNiveau,-20001);
    blocageDate exception;
    pragma exception_init(blocageDate,-20002);
	donneesInexistantes exception;
    pragma exception_init(donneesInexistantes, 100);
	
BEGIN 
	-- En début de partie, on ne peut pas renseigné les valeurs du temps, de l'etat et de la date de fin de partie.
    insert into Partie values (SEQ_PARTIE.nextval,NULL,NULL,NULL,vJoueur,vFigure);
    commit;
    retour:=0;
	
EXCEPTION

	-- Erreur qui ne doit jamais arriver vu qu'on utilise une séquence.
	When DUP_VAL_ON_INDEX Then
        retour:=1;
        --DBMS_OUTPUT.PUT_LINE('Duplication clé primaire - Cet identifiant de partie existe déjà dans la base.');

	-- Données inexistantes
	when donneesInexistantes Then 
        retour:=14;
        --DBMS_OUTPUT.PUT_LINE('Le joueur et/ou la figure n''existe(nt) pas')

	-- Erreur n°1 du trigger t_b_i_Partie
    When blocageNiveau Then
        retour:=43;
        --DBMS_OUTPUT.PUT_LINE('Le joueur n a pas acces à ce niveau.');

	-- Erreur n°2 du trigger t_b_i_Partie
    When blocageDate Then 
		retour :=44;
		--DBMS_OUTPUT.PUT_LINE('Le joueur a perdu 5 partie en une heure il est bloqué pendant 4h');	

	-- Autres erreurs
    When Others Then
        retour:=SQLCODE;
        --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
END;
/

-- 
/*
Procédure 'fin_partie', utilisée pour renseigner les attributs d'une partie venant de se terminer. On vérifie également les erreurs éventuelles.
Entrées : vTemps -> temps qu'a mis le joueur pour réalisé la figure demandéee
 		  vDate -> date à la fin de la partie 
		  vEtat -> si la partie est réussie 'succes' sinon 'echec'
		  vPartie -> identifiant de la partie venant de se terminer 
Sortie -> retour : code de retour qui sera traité dans le code Python
*/
create or replace procedure fin_partie (vTemps IN Partie.temps%type, vDate IN Partie.datePartie%type, vEtat IN Partie.etat%type, vPartie IN Partie.idPartie%type, retour OUT number) is
	-- Déclarations variables		
    vNvEtat Partie.etat%type := 'succes';
	lejoueur Partie.joueurPartie%type;
    mdp Joueur.motPasse%type;
    niveau Joueur.niveauMax%type;
	score number;
    nbrate number;    
	dateBlocage DATE :=null;
    ret number := 0;
    
	-- Déclarations exceptions
	pbCheck exception;
    pragma exception_init(pbCheck,-2290);
    partieInexistante exception;
    pragma exception_init(partieInexistante, 100);
  
BEGIN
	
	-- On commence par mettre à jour les informations qui était à Null vu que la partie n'était pas finie (temps, état et date).
    update partie
    set temps=vTemps, datePartie=vDate, etat=vEtat
    where idPartie=vPartie;
    commit;

	-- On calcule le score
    score:= packageScore.Score_Partie(vPartie);
	
	-- Si le score est zéro, on modifie l'état pour considérer la partie comme perdue (cf rapport).
    if score=0 then
        vNvEtat := 'echec';
    end if;
	
    update partie 
    set etat=vNvEtat
    where idPartie=vPartie;
    commit;
	    
   	-- Si la partie est perdue, on doit vérifier que le quota de cinq parties perdues en une heure n'est pas dépassé. Sinon on doit bloquer le joueur
    if vNvEtat='echec' then

		-- On récupère les informations du joueurs
		select j.idJoueur, j.motPasse, j.niveauMax into lejoueur, mdp, niveau
	    from Partie p, Joueur j
	    where p.idPartie=vPartie and p.JoueurPartie=j.idJoueur;

		-- On compte le nombre de parties perdues dans l'heure
        select count(*) into nbrate
        from Partie
        where joueurPartie=lejoueur
        and Etat='echec'
        and datePartie between sysdate-1/24 and sysdate;
        
		-- Si ce nombre est supérieur ou égal à 5 (normalement il ne peut pas être supérieur vu qu'on vérifie à la fin de chaque partie), on modifie la date de blocage dans la table Joueur pour bloquer le joueur pendant 4 heures.
		if nbrate >= 5 then 
            dateBlocage := SYSDATE+4/24;
			update_joueur(lejoueur, mdp, niveau, dateBlocage, ret);
        end if;
    end if;
	
	-- Si on est passé dans le if, 'ret' vaudra le retour de la procédure update_joueur (0 si c'est ok, autre valeur sinon). 
	-- En revanche, si on ne passe pas dans le if, ret vaudra 0 (valeur par défaut).
	retour:=ret;
	
EXCEPTION 
	-- Données inexistantes
	when partieInexistante Then 
        retour:=16;
        --DBMS_OUTPUT.PUT_LINE('La partie n''existe pas');

	-- Erreurs liées aux contraintes CHECK
    When pbCheck Then
    	if (SQLERRM like '%CH_TEMPS%') then
            retour:=28;
            --DBMS_OUTPUT.PUT_LINE('Le temps doit être supérieur ou égal à 0 ou null');
        elsif (SQLERRM like '%CH_ETAT%') then
            retour:=29;
            --DBMS_OUTPUT.PUT_LINE('La valeur de l état doit être "succes" ou "echec" ou null');
        else 
            retour:=SQLCODE;
            --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
        end if;

	-- Autres erreurs
    When Others Then
        retour:=SQLCODE;
        --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
END;
/


/*
Procédure 'inserer_historique', utilisée pour insérer les actions effectuées par l'utilisateur au cours de sa partie dans la table Historique et vérifier les erreurs éventuelles.
Entrées : vIdAction -> identifiant de l'action effectuée
		  vPartie -> identifiant de la partie concernée 
		  x -> coordonnées selon l'axe horizontal
		  y -> coordonnées selon l'axe vertical 
Sortie -> retour : code de retour qui sera traité dans le code Python
*/
create or replace procedure inserer_historique ( vIdAction IN Action.idAction%TYPE, vPartie IN Partie.idPartie%TYPE, x IN number, y IN number, retour OUT number) is 
    pbCheck exception;
    pragma exception_init(pbCheck,-2290);
    pbFK exception;
    pragma exception_init(pbFK,-2291);
    pbNull exception;
    pragma exception_init(pbNull,-1400);
    
BEGIN 

    insert into HISTORIQUE values (vIdAction, vPartie, x, y, SEQ_ORDRE.nextval);
    commit;
    retour:=0;
    
EXCEPTION
	-- Erreur de clé primaire (comme ordre est inséré via une séquence, cette erreur ne devrait jamais arriver)
    When DUP_VAL_ON_INDEX Then
        retour:=1;
        --DBMS_OUTPUT.PUT_LINE('Duplication clé primaire - L'identifiant d''historique (idAction,idPartie,x,y,ordre) existe déjà dans la base.');
	
	-- Erreurs de clés étrangères
    When pbFK Then
		if (SQLERRM like '%FK_IDPARTIEHISTORIQUE%') then
            retour:=11;
            --DBMS_OUTPUT.PUT_LINE('Clé étrangère inexistante - Cette partie n exite pas');
        elsif (SQLERRM like '%FK_IDACTIONHISTORIQUE%') then
            retour:=12;
            --DBMS_OUTPUT.PUT_LINE('Clé étrangère inexistante - Cette action n exite pas');
        else 
            retour:=SQLCODE;
            --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
        end if;

	-- Erreurs liées aux contraintes CHECK
    When pbCheck Then
        if (SQLERRM like '%CH_XHISTORIQUE%') then
            retour:=26;
            --DBMS_OUTPUT.PUT_LINE('X doit être compris entre 1 et 10 ou -1');
        elsif (SQLERRM like '%CH_YHISTORIQUE%') then
            retour:=27;
            --DBMS_OUTPUT.PUT_LINE('Y doit être compris entre 1 et 10');
        else 
            retour:=SQLCODE;
            --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
        end if;
	
	-- Erreurs liées aux contraintes CHECK (Not Null)
    When pbNull Then
        if (SQLERRM like '%X%') then
            retour:=36;
            --DBMS_OUTPUT.PUT_LINE('X ne peut être nulle');
        elsif (SQLERRM like '%Y%') then
            retour:=37;
            --DBMS_OUTPUT.PUT_LINE('Y ne peut être nulle');
        elsif (SQLERRM like '%ORDRE%') then
            retour:=38;
            --DBMS_OUTPUT.PUT_LINE('L''ordre ne peut être null');
        elsif (SQLERRM like '%ACTION%') then
            retour:=39;
            --DBMS_OUTPUT.PUT_LINE('L''idAction ne peut être null');
        elsif (SQLERRM like '%PARTIE%') then
            retour:=40;
            --DBMS_OUTPUT.PUT_LINE('L''idPartie ne peut être null');
        else 
            retour:=SQLCODE;
            --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
        end if;

	-- Autres erreurs
    When Others Then
        retour:=SQLCODE;
        --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
END;
/

--
/*
Procédure 'etat_null', utilisée à chaque fois qu'un joueur se connecte. Elle permet de gérer le problème qui intervient lorsqu'un joueur quitte une partie directement (en fermant la page ou la navigateur). La procédure inserer_partie aura alors été exécutée, mais pas fin_partie. Ainsi, les attributs 'temps, 'datePartie' et 'etat' restent à NULL. 
etat_null permet alors de modifier l'état de la partie en mettant 'echec'. De plus, elle permet de modifier la date et mettre SYSDATE (la date courante). Cela pénalisera le joueur puisqu’il aura une partie de plus perdue dans l’heure alors que peut-être que la partie qu’il a quitté en fermant le site datait d’il y a plusieurs heures ou plusieurs jours. Cette pénalité est voulue. On aurait pu très bien créer une variable « dateDernièreConnexion » et obtenir la vraie date de la partie, mais nous souhaitions vraiment sanctionner les joueurs qui quittent parce qu’ils ne réussissent pas leur partie. En revanche, si un joueur quitte par maladresse nous estimons qu’il se reconnectera dans la foulée donc il ne sera pas pénalisé (même s’il est vrai qu’il aurait peut-être réussi sa partie, nous sanctionnons donc sa maladresse en considérant la partie comme perdue). 
Par conséquent, on doit à la fin de cette procédure vérifier que le joueur n'ait pas dépassé le quota de parties perdues en une heure. Si c'est le cas, on appelle la procédure 'update_joueur' pour modifier la date de blocage.
Entrée : vIdJoueur -> identifiant du joueur connecté 
Sortie : retour -> code de retour qui sera traité dans le code Python
*/
create or replace procedure etat_null (vIdJoueur IN Joueur.idJoueur%type, retour OUT number) as
	-- Déclarations variables     
	mdp Joueur.motPasse%type;
    niveau Joueur.niveauMax%type;
	nbrate number;
    dateBlocage DATE :=null;
	ret number := 0;
	
	-- Déclarations exceptions
	pbJoueur exception;
    pragma exception_init(pbJoueur,100);
	
BEGIN
	-- On met à jour les informations de la partie qui sont restées à Null vu que la procédure 'fin_partie' n'a pas été appelée.
    update partie
	set etat='echec' , datePartie=Sysdate
	where etat is null 
	and joueurPartie=vIdJoueur;
    
	commit;

	-- Comme la partie est perdue, on doit vérifier que le quota de cinq parties perdues en une heure n'est pas dépassé. Sinon on doit bloquer le joueur
	-- On récupère les informations du joueurs	
	select j.motPasse, j.niveauMax into mdp, niveau
    from  Joueur j
	where idJoueur=vIdJoueur;

	-- On compte le nombre de parties perdues dans l'heure
    select count(*) into nbrate
    from Partie
    where joueurPartie=vIdJoueur
    and Etat='echec'
    and datePartie between sysdate-1/24 and sysdate;
    
	-- Si ce nombre est supérieur ou égal à 5, on modifie la date de blocage dans la table Joueur afin de bloquer le joueur pendant 4 heures.
	if nbrate >= 5 then 
        dateBlocage := SYSDATE+4/24;
        update_joueur(vIdJoueur, mdp, niveau, dateBlocage, ret);	
    end if;

	-- Si on est passé dans le if, 'ret' vaudra le retour de la procédure update_joueur (0 si c'est ok, autre valeur sinon). 
	-- En revanche, si on ne passe pas dans le if, ret vaudra 0 (valeur par défaut).
	retour:=ret;
        
EXCEPTION

	-- Données inexistantes
    When pbJoueur Then
        retour:=13;
        --DBMS_OUTPUT.PUT_LINE('Ce joueur n existe pas.');
    
	-- Autres erreurs
	When Others Then
        retour:=SQLCODE;
        --DBMS_OUTPUT.PUT_LINE(SQLCODE||' '||SQLERRM);
END;
/
