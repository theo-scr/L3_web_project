/*
Script pour insérer les données dans certaines tables de la base de données.
Insertion dans les tables : FIGURE, ACTION et NIVEAU.
*/

-- Insertion NIVEAU 
insert into NIVEAU values (1, 15, 180);
insert into NIVEAU values (2, 10, 160);
insert into NIVEAU values (3, 15, 140);
insert into NIVEAU values (4, 20, 120);

-- Insertion ACTION  
insert into ACTION values (1, 'Colorie la case', 'rouge'); 
insert into ACTION values (2, 'Colorie la case', 'orange');
insert into ACTION values (3, 'Colorie la case', 'vert');
insert into ACTION values (4, 'Colorie la case', 'violet');
insert into ACTION values (5, 'Colorie la case', 'bleu');
insert into ACTION values (6, 'Colorie la case', 'rose');
insert into ACTION values (7, 'Aide', null);
insert into ACTION values (8, 'Validation', null);
insert into ACTION values (9, 'Enleve la couleur', null);

commit;

-- Insertion FIGURE 
-- On utilise la procédure 'inserer_figure'.

set serveroutput on;

DECLARE
  retour number;

BEGIN
    inserer_figure(12, 1, 1, retour);
    DBMS_OUTPUT.PUT_LINE(retour);
	inserer_figure(38, 2, 1, retour);
    DBMS_OUTPUT.PUT_LINE(retour);
	inserer_figure(22, 3, 2, retour);
    DBMS_OUTPUT.PUT_LINE(retour);
	inserer_figure(31, 2, 2, retour);
    DBMS_OUTPUT.PUT_LINE(retour);
	inserer_figure(46, 3, 3, retour);
    DBMS_OUTPUT.PUT_LINE(retour);
	inserer_figure(30, 3, 3, retour);
    DBMS_OUTPUT.PUT_LINE(retour);
	inserer_figure(56, 4, 4, retour);
    DBMS_OUTPUT.PUT_LINE(retour);	
	inserer_figure(60, 4, 4, retour);
    DBMS_OUTPUT.PUT_LINE(retour);
END;
/
