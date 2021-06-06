/*
Script pour créer les tables de la base de données.
Création des tables : REPRESENTAION, HISTORIQUE, PARTIE, FIGURE, JOUEUR, ACTION et NIVEAU.
*/

-- Suppression des séquences et tables (ordre inverse de création)
drop table REPRESENTATION;
drop table HISTORIQUE;
drop table PARTIE;
drop table FIGURE;
drop table JOUEUR;
drop table ACTION;
drop table NIVEAU;

drop sequence SEQ_FIGURE;
drop sequence SEQ_PARTIE;
drop sequence SEQ_ORDRE;


-- Création des tables

create table NIVEAU (
    idNiveau number,
    dureeAffichage number, --en secondes
    dureeRealisation number, --en secondes

    constraint pk_idNiveau primary key(idNiveau),
    constraint ch_idNiveau check (idNiveau between 1 and 4),
    constraint ch_dureeAffichage check (dureeAffichage > 0),
    constraint ch_dureeRealisation check (dureeRealisation > 0),
    constraint nn_dureeAffichage check (dureeAffichage is not null),
    constraint nn_dureeRealisation check (dureeRealisation is not null)
    );
    
create table ACTION (
    idAction number, 
    libelle varchar(35),
    couleur varchar(10), -- peut être NULL pour certaines actions

    constraint pk_idAction primary key(idAction),
    constraint ch_couleurAction check (couleur in ('rouge','orange','vert','violet','bleu','rose')), -- si NULL, contrainte respectée
    constraint ch_idAction check (idAction between 1 and 9),
    constraint nn_libelle check (libelle is not null)
    );

create table JOUEUR (
    idJoueur varchar(20),
    motPasse varchar(20),
    niveauMax number, -- la valeur par défaut est 1 (affectée lors de la procédure 'inserer_joueur')
    dateBlocage DATE,

    constraint pk_idJoueur primary key(idJoueur),
    constraint fk_niveauJoueur foreign key (niveauMax) references Niveau(idNiveau),
    constraint nn_motPasse check (motPasse is not null),
    constraint nn_niveauMax check (niveauMax is not null)
    );
 
create table FIGURE (
    idFigure number, --auto increment
    nbCasesColoriees number,
    nbCouleursFigure number,
    niveauFigure number,

    constraint pk_idFigure primary key(idFigure),
    constraint fk_niveauFigure foreign key (niveauFigure) references Niveau(idNiveau),
    constraint ch_nbCasesColoriees check (nbCasesColoriees between 1 and 100),
    constraint ch_nbCouleursFigure check (nbCouleursFigure between 1 and 6),
    constraint nn_nbCasesColoriees check (nbCasesColoriees is not null),
    constraint nn_nbCouleursFigure check (nbCouleursFigure is not null),
    constraint nn_niveauFigure check (niveauFigure is not null)
    );

create table PARTIE (
    idPartie number, --auto increment
    temps number, --temps mis pour faire la figure (en secondes)
    datePartie date, --date de fin de partie (et non de début)
    etat varchar(6), -- permet de savoir si la partie a été réussie ou perdue
    joueurPartie varchar(20),
    figurePartie number,

    constraint pk_idPartie primary key(idPartie),
    constraint fk_figurePartie foreign key (figurePartie) references Figure(idFigure),
    constraint fk_joueurPartie foreign key (joueurPartie) references Joueur(idJoueur),
    constraint ch_etat check (etat in ('succes','echec')),
    constraint ch_temps check (temps>=0),
    -- temps, datePartie et etat ont besoin de ne pas être not null car nous insérons les données d'une partie en deux temps, avec deux procédures
    constraint nn_joueurPartie check (joueurPartie is not null),
    constraint nn_figurePartie check (figurePartie is not null)
    );

create table HISTORIQUE (
    idAction number,
    idPartie number,
    x number, 
    y number,
    ordre number, --auto increment

    constraint pk_Historique primary key(idAction,idPartie,x,y,ordre),
    constraint fk_idActionHistorique foreign key (idAction) references Action(idAction),
    constraint fk_idPartieHistorique foreign key (idPartie) references Partie(idPartie),
    constraint ch_xHistorique check (x between 1 and 10 or x=-1),
    constraint ch_yHistorique check (y between 1 and 10),
    constraint nn_HISTORIQUEy check (y is not null),
    constraint nn_HISTORIQUEx check (x is not null),
    constraint nn_ordre check (ordre is not null)
    );

create table REPRESENTATION (
    idFigure number,
    x number, 
    y number,
    couleur varchar(10), --peut être null

    constraint pk_Representation primary key(idFigure,x,y),  
    constraint fk_idFigureRepresentation foreign key (idFigure) references Figure(idFigure),
    constraint ch_couleurRepresentation check (couleur in ('rouge','orange','vert','violet','bleu','rose')),
    constraint ch_xRepresentation check (x between 1 and 10),
    constraint ch_yRepresentation check (y between 1 and 10),
    constraint nn_REPRESENTATIONy check (y is not null),
    constraint nn_REPRESENTATIONx check (x is not null)
    );


-- Création des séquences

create sequence SEQ_PARTIE start with 1 increment by 1;
create sequence SEQ_FIGURE start with 1 increment by 1;
create sequence SEQ_ORDRE start with 1 increment by 1;



