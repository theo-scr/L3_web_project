/*
Dans le langage PL/SQL, un package permet de regrouper plusieurs procédures ou fonctions ayant des caractéristiques communes. 
Ainsi, nous avons fait le choix de créer un package ‘packageScore’ regroupant une fonction (‘Score_Partie’) et quatre procédures (‘Score_Niveau_1J’, ‘Score_Journee_1J’, ‘Score_Niveau_MJ’ et ‘Score_Journee_MJ’) qui permettent toutes d’obtenir différents scores. 
Ces scores seront utilisés notamment dans les tableaux de Highscores présent sur notre site. 
*/

---- Partie Spécification => déclaration des procédures et fonctions du package.
CREATE or REPLACE PACKAGE packageScore AS
    FUNCTION Score_Partie(vIdPartie PARTIE.idPartie%TYPE) RETURN NUMBER;
    PROCEDURE Score_Niveau_1J (vIdJoueur IN JOUEUR.idJoueur%TYPE, scoreN1 OUT NUMBER, scoreN2 OUT NUMBER, scoreN3 OUT NUMBER, scoreN4 OUT NUMBER);
    PROCEDURE Score_Journee_1J(vIdJoueur IN JOUEUR.idJoueur%TYPE, maxScore OUT NUMBER);
    PROCEDURE Score_Niveau_MJ (bestJoueurN1 OUT JOUEUR.idJoueur%TYPE, bestJoueurN2 OUT JOUEUR.idJoueur%TYPE, bestJoueurN3 OUT JOUEUR.idJoueur%TYPE, bestJoueurN4 OUT JOUEUR.idJoueur%TYPE, scoreN1 OUT NUMBER, scoreN2 OUT NUMBER, scoreN3 OUT NUMBER, scoreN4 OUT NUMBER);
    PROCEDURE Score_Journee_MJ(bestJoueur OUT JOUEUR.idJoueur%TYPE, maxScore OUT NUMBER);
END packageScore;
/

---- Partie BODY =>  comporte le corps des procédures et fonctions du package.
CREATE or REPLACE PACKAGE BODY packageScore AS

/* 
Fonction 'Score_Partie', sert à calculer le score d'une partie
Entrée : vIdPartie : identifiant de la partie dont on souhaite calculer le score
*/
FUNCTION Score_Partie(vIdPartie PARTIE.idPartie%TYPE) RETURN NUMBER IS
	score NUMBER;
	vNbAide NUMBER;
	vNbValidationFausse NUMBER;
	vTemps PARTIE.temps%TYPE;
	vEtat PARTIE.etat%TYPE;

BEGIN
    -- On récupère l'état de la partie
    SELECT etat INTO vEtat
    FROM PARTIE 
    WHERE idPartie = vIdPartie;
    
	-- Si la partie est réussie, on calcul le score de la partie
    IF (vEtat = 'succes') THEN 

		-- On compte le nombre de fois où le joueur a utilisé l'aide
		SELECT COUNT(*) INTO vNbAide
    	FROM HISTORIQUE H, ACTION A
    	WHERE H.idAction=A.idAction AND H.idPartie=vIdPartie AND A.libelle='Aide'; 
		-- Remarque: Au lieu de faire une faire une jointure, on aurait pu uniquement utiliser la table HISTORIQUE avec comme idAction = 7.

		
		-- On compte le nombre de fois où le joueur a validé une mauvaise figure. On enlève 1 car la partie est réussie, donc la dernière validation n'est pas une validation incorrecte
        SELECT COUNT(*)-1 INTO vNbValidationFausse
        FROM HISTORIQUE H, ACTION A
        WHERE H.idAction=A.idAction AND H.idPartie=vIdPartie AND A.libelle='Validation';
		
		-- On stocke le temps mis pour réaliser la figure
        SELECT temps INTO vTemps
        FROM PARTIE 
        WHERE idPartie = vIdPartie;
        
		-- Calcul du score
        score := (vNbAide * (-100) + vNbValidationFausse * (-50) + (vTemps*(-3) + 1000));
		-- On fait le choix de pénaliser plus une demande d'aide qu'une validation incorrecte. 
		
		-- On ne souhaite pas avoir de score négatif, si c'est le cas, le score est remis à 0
		IF (score < 0) THEN 
			score := 0;
		END IF;
	
	-- Si la partie est perdue, le score est automatiquement 0
    ELSE 
        score := 0;
    END IF;

    RETURN score;
   
END Score_Partie;

/*
Procédure 'Score_Niveau_1J', sert à calculer le meilleur score d'un joueur pour chaque niveau
Entrée : vIdJoueur : identifiant du joueur connecté 
Sorties : scoreN1, scoreN2, scoreN3, scoreN4 : scores de chaque niveau
*/
PROCEDURE Score_Niveau_1J (vIdJoueur IN JOUEUR.idJoueur%TYPE, scoreN1 OUT NUMBER, scoreN2 OUT NUMBER, scoreN3 OUT NUMBER, scoreN4 OUT NUMBER) AS
	-- Variables	
	maxScore NUMBER;
	score NUMBER;
	
	-- Curseurs	
	CURSOR c_niveau IS (SELECT DISTINCT idNiveau FROM NIVEAU);
    CURSOR c_score(vIdN NIVEAU.idNiveau%TYPE) IS (SELECT p.idPartie FROM PARTIE p, FIGURE f WHERE f.idFigure=p.figurePartie AND  F.niveauFigure=vIdN AND p.joueurPartie=vIdJoueur);                                                                  

BEGIN    
	-- Curseur parcourant tous les niveaux un par un
    FOR c_niveau_ligne IN c_niveau LOOP
		-- Le score maximal de base est 0
        maxScore := 0;

		-- Curseur parcours toutes les parties du joueur pour le niveau actuel
        FOR c_score_ligne IN c_score(c_niveau_ligne.idNiveau) LOOP
			-- On calcule le score de la partie
            score := Score_Partie(c_score_ligne.idPartie);

			-- On regarde si le score de la partie est plus grand que le score maximal. Si oui, on met à jour le score maximal, sinon on ignore.
            IF(score > maxScore) THEN 
                maxScore := score;
            END IF;
        END LOOP;
        
		-- En fonction du niveau actuel, on stocke son meilleur résultat dans la variable de sortie correspondante
        IF (c_niveau_ligne.idNiveau = 1) THEN 
            scoreN1 := maxScore;
        ELSIF (c_niveau_ligne.idNiveau = 2) THEN 
            scoreN2 := maxScore;
        ELSIF (c_niveau_ligne.idNiveau = 3) THEN 
            scoreN3 := maxScore;
        ELSE 
            scoreN4 := maxScore;
        END IF;
    END LOOP;
    
END Score_Niveau_1J;

/*
Procédure 'Score_Journee1J', sert à calculer le meilleur score d'un joueur pour la journée en cours
Entrée : vIdJoueur : identifiant du joueur connecté 
Sorties : maxScore : score le plus élevé pour la journée en cours
*/
PROCEDURE Score_Journee_1J(vIdJoueur IN JOUEUR.idJoueur%TYPE, maxScore OUT NUMBER) IS
	-- Variables	
	vDebutDateJour DATE;
	vFinDateJour DATE;
	score NUMBER;

	-- Curseur	
	CURSOR c_partie(vDebut DATE, vFin DATE) IS ( SELECT DISTINCT idPartie FROM PARTIE WHERE (datePartie BETWEEN vDebut AND vFin) AND joueurPartie=vIdJoueur);

BEGIN
	-- On détermine la date de début et de fin de la journée
    vDebutDateJour := TO_CHAR(SYSDATE, 'DD/MM/YY');
    vFinDateJour := TO_CHAR(SYSDATE+1, 'DD/MM/YY');

	-- Le score maximal de base est 0
	maxScore := 0;
    
	-- Pour chaque partie comprise entre la date de début et de fin
    FOR c_partie_ligne IN c_partie(vDebutDateJour,vFinDateJour ) LOOP

		-- On calcule le score de la partie
        score := Score_Partie(c_partie_ligne.idPartie);

		-- On regarde si le score de la partie est plus grand que le score maximal. Si oui, on met à jour le score maximal, sinon on ignore.
        IF(score > maxScore) THEN 
            maxScore := score;
        END IF;
    END LOOP;
    
END Score_Journee_1J;

/*
Procédure 'Score_Niveau_MJ', permet de calculer le meilleur score pour chaque niveau et avoir le pseudo du meilleur joueur (tout joueur confondu)
Entrée : aucune entrée 
Sorties : 	scoreN1, scoreN2, scoreN3, scoreN4 : meilleurs scores de chaque niveau
			bestJoueurN1, bestJoueurN2, bestJoueurN3, bestJoueurN4 : pseudos des meilleurs joueurs de chaque niveau
*/
PROCEDURE Score_Niveau_MJ (bestJoueurN1 OUT JOUEUR.idJoueur%TYPE, bestJoueurN2 OUT JOUEUR.idJoueur%TYPE, bestJoueurN3 OUT JOUEUR.idJoueur%TYPE, bestJoueurN4 OUT JOUEUR.idJoueur%TYPE, scoreN1 OUT NUMBER, scoreN2 OUT NUMBER, scoreN3 OUT NUMBER, scoreN4 OUT NUMBER) AS
	-- Variables 	
	maxScore NUMBER;
	score NUMBER;
	joueur PARTIE.joueurPartie%TYPE;
	
	-- Curseurs	
	CURSOR c_niveau IS (SELECT DISTINCT idNiveau FROM NIVEAU);                   
	CURSOR c_score(vIdN NIVEAU.idNiveau%TYPE) IS (SELECT p.idPartie, p.joueurPartie FROM PARTIE p, FIGURE f WHERE f.idFigure=p.figurePartie AND  F.niveauFigure=vIdN);                                                                  

BEGIN
    
	-- Curseur parcourant tous les niveaux un par un
    FOR c_niveau_ligne IN c_niveau LOOP
		
		-- Le score maximal initial est 0
        maxScore := 0;
		-- De base, on ne connait pas le joueur qui a fait le score maximal
        joueur := NULL;
        
		-- Curseur parcours toutes les parties du niveau actuel (on a comme informations l'identifiant de la partie, et l'identifiant du joueur)
        FOR c_score_ligne IN c_score(c_niveau_ligne.idNiveau) LOOP

			-- On calcule le score de la partie
            score := Score_Partie(c_score_ligne.idPartie);
			
			-- On regarde si le score de la partie est plus grand que le score maximal. Si oui, on met à jour le score maximal et le pseudo du joueur qui a réalisé cette performance
            IF(score > maxScore) THEN 
                maxScore := score;
                joueur := c_score_ligne.joueurPartie;
            END IF;
        END LOOP;
        
		-- En fonction du niveau actuel, on stocke les scores maximaux et les pseudos des joueurs ayant réalisés ces scores dans les variables de sorties correspondantes
        IF (c_niveau_ligne.idNiveau = 1) THEN 
            scoreN1 := maxScore;
            bestJoueurN1 := joueur;
        ELSIF (c_niveau_ligne.idNiveau = 2) THEN 
            scoreN2 := maxScore;
            bestJoueurN2 := joueur;
        ELSIF (c_niveau_ligne.idNiveau = 3) THEN 
            scoreN3 := maxScore;
            bestJoueurN3 := joueur;
        ELSE 
            scoreN4 := maxScore;
            bestJoueurN4 := joueur;
        END IF;
    END LOOP;
    
END Score_Niveau_MJ;

/*
Procédure 'Score_Journee_MJ', sert à avoir le meilleur score obtenu lors la journée en cours (tout niveau et joueur confondu)
Entrée : aucune
Sorties : 	maxScore : score le plus élevé pour la journée en cours tout joueur confondu
			bestJoueur : pseudo du meilleure joueur de la journée
*/
PROCEDURE Score_Journee_MJ(bestJoueur OUT JOUEUR.idJoueur%TYPE, maxScore OUT NUMBER) IS
	-- Variables	
	vDebutDateJour DATE;
	vFinDateJour DATE;
	score NUMBER;
	
	-- Curseur	
	CURSOR c_partie(vDebut DATE, vFin DATE) IS ( SELECT DISTINCT idPartie, joueurPartie FROM PARTIE WHERE (datePartie BETWEEN vDebut AND vFin ));
    
BEGIN
	-- Le score maximal de base est 0
    maxScore := 0;
	-- De base, on ne connait pas le joueur qui a fait le score maximal
    bestJoueur := NULL;

	-- On détermine la date de début et de fin de la journée
    vDebutDateJour := TO_CHAR(SYSDATE, 'DD/MM/YY');
    vFinDateJour := TO_CHAR(SYSDATE+1, 'DD/MM/YY');
	
	-- Pour chaque partie comprise entre la date de début et de fin
    FOR c_partie_ligne IN c_partie(vDebutDateJour, vFinDateJour) LOOP 
		
		-- On calcule le score de la partie
        score := Score_Partie(c_partie_ligne.idPartie);
		
		-- On regarde si le score de la partie est plus grand ou pas que le score maximal. Si oui, on met à jour le score maximal et le pseudo du joueur qui a réalisé cette performance
        IF(score > maxScore) THEN 
            maxScore := score;
            bestJoueur := c_partie_ligne.joueurPartie;
        END IF;
    END LOOP;
    
END Score_Journee_MJ;

END packageScore;
/





