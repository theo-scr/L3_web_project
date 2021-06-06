/*
Le trigger t_b_i_Partie permet de gérer des éventuelles erreurs avant l’insertion d’une partie dans la Partie.
Il permet de vérifier si le joueur a bien accès au niveau de cette partie (le niveau est débloqué)
et de vérifier si le joueur n’est pas bloqué pendant 4 heures suite à 5 parties échouées en 1 heure.
*/

CREATE OR REPLACE TRIGGER t_b_i_Partie
BEFORE INSERT ON PARTIE
FOR EACH ROW

DECLARE
    vNiveauPartie FIGURE.niveauFigure%TYPE;
    vNiveauJoueur JOUEUR.niveauMax%TYPE;
    vDateBlocage JOUEUR.dateBlocage%TYPE;
    
BEGIN
	
	-- On stocke le niveau de la figure
    SELECT niveauFigure INTO vNiveauPartie
    FROM FIGURE 
    WHERE idFigure = :new.figurePartie;
    
	-- On stocke le niveau maximal débloqué par le joueur
    SELECT niveauMax INTO vNiveauJoueur
    FROM JOUEUR
    WHERE idJoueur = :new.joueurPartie;
    
	-- On vérifie si le joueur a accès à ce niveau. Si ce n'est pas le cas, on déclenche une erreur applicative pour empêcher l'insertion et donc empêcher la partie de se lancer. (Trigger 1)
    IF (vNiveauPartie > vNiveauJoueur) THEN  
        RAISE_APPLICATION_ERROR(-20001, 'Le joueur n''a pas accès à ce niveau.');
    END IF;
    
    -- On stocek aussi la date jusqu'à laquelle le joueur est bloqué suite à de trop nombreuses parties perdues (Elle peut être à NULL si le joueur n'est pas bloqué) 
    SELECT dateBlocage INTO vDateBlocage
    FROM JOUEUR
    WHERE idJoueur = :new.joueurPartie;
    
	-- On vérifie si elle est supérieure à SYSDATE (date actuelle). Si c'est le cas, le joueur est encore bloqué, on déclenche une erreur applicative pour empêcher la partie de s'insérer dans la table et donc empêcher le lancement. (Trigger 2)
    IF (vdateBlocage > SYSDATE) THEN 
        RAISE_APPLICATION_ERROR (-20002, 'Le joueur a perdu 5 partie en une heure il est bloqué pendant 4h');
    END IF;
    
END;
/

/*
Le trigger t_a_u_Joueur permet de gérer des éventuelles erreurs lors de la modification du niveau maximal débloqué pour un joueur. 
Remarque : Dans le code python, pour chaque partie gagné, on incrémente le niveau de 1 (on ne fait aucune vérification), c'est ce trigger qui nous empêchera l'augmentation.
*/

CREATE OR REPLACE TRIGGER t_a_u_Joueur
AFTER UPDATE ON JOUEUR 
FOR EACH ROW 

DECLARE
    vNbPartieNiveauPr NUMBER;

BEGIN

    -- On vérifie d'abord que c'est bien le niveau qu'on a modifié lorsqu'on a appellé l'ordre UPDATE JOUEUR
    IF (:new.niveauMax != :old.niveauMax)  THEN
        
        -- Si le nouveau niveau n'est pas le niveau juste au-dessus du niveau actuel, on déclenche une erreur. (Cela ne devrait jamais arriver car on incrémente le niveau de un dans le Python)
        IF (:new.niveauMax != :old.niveauMax+1) THEN
            RAISE_APPLICATION_ERROR(-20003, 'On peut seulement augmenter le niveau d''un cran');    
        END IF;
        
		-- On compte le nombre de figures réussies (donc le score doit être supérieur à zéro!) pour ce niveau
        SELECT COUNT(  DISTINCT (p.figurePartie) ) INTO vNbPartieNiveauPr
        FROM PARTIE p, FIGURE f
        WHERE p.figurePartie = f.idFigure AND p.joueurPartie = :old.idJoueur AND f.niveauFigure = :old.niveauMax AND  packageScore.Score_Partie(p.idPartie) >0;
    
		-- Si le nombre de figures réussies pour ce niveau est différent de 2 (il y a 2 figures par niveau) alors il ne faut pas augmenter le niveau. On déclenche une erreur applicatuve empêchant la modification du niveau maximal.
        IF (vNbPartieNiveauPr != 2) THEN 
            RAISE_APPLICATION_ERROR(-20004, 'Le joueur n''a pas réussi toutes les figures du niveau précédent pour pouvoir augmenter de niveau');    
        END IF;
	
        -- Remarque: On gère que le niveau soit compris entre 1 et 4 avec la contrainte Oracle liée à la clé étrangère. (En réalité, comme lors de la création d'un joueur le niveau maximal est par défaut 1 et qu'on incrémente ce niveau de 1, cette contrainte permet de vérifier qu'on ne dépasse pas 4).

    END IF;

END;
/
