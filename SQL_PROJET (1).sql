-- ÉTUDE GLOBAL --
-- RÉALISÉ PAR VU TIEN DAT - BUI THUY TIEN - INES Zouari 																				
-- I. Répartition Adhérant / VIP --  
SELECT 
	  SUM(CASE WHEN VIP = 1 THEN 1 ELSE 0 END) AS VIP,
	  
	  SUM(CASE WHEN datedebutadhesion BETWEEN '2016-01-01' AND '2016-12-31' 
		  	AND VIP <> 1
		  	THEN 1 ELSE 0 END) AS NEW_N2,
			
	  SUM(CASE WHEN datedebutadhesion BETWEEN '2017-01-01' AND '2017-12-31'  
		  	AND VIP <> 1 
		  	THEN 1 ELSE 0 END) AS NEW_N1,
			
	  SUM(CASE WHEN datedebutadhesion NOT BETWEEN '2016-01-01' AND '2016-12-31'
		  	 AND datedebutadhesion NOT BETWEEN '2017-01-01' AND '2017-12-31'  
		  	 AND datefinadhesion > '2018-01-01'  
		     AND VIP <> 1 THEN 1 ELSE 0 END) AS ADHERENT,
			 
	  SUM(CASE WHEN datefinadhesion < '2018-01-01'  
		  AND VIP <> 1 
		  AND datedebutadhesion NOT BETWEEN '2016-01-01' AND '2016-12-31'
		  AND datedebutadhesion NOT BETWEEN '2017-01-01' AND '2017-12-31'   
		  THEN 1 ELSE 0 END) AS CHURNER
FROM client;


-- II. Comportement du CA GLOBAL par client N-2 vs N-1 -- 
SELECT idclient, sum(tic_totalttc),extract(year from tic_date) as year
FROM entete_ticket
	WHERE tic_totalttc  < (SELECT AVG(tic_totalttc) - 3 * STDDEV(tic_totalttc) FROM entete_ticket)
   		OR tic_totalttc > (SELECT AVG(tic_totalttc) + 3 * STDDEV(tic_totalttc) FROM entete_ticket)
	GROUP BY idclient, year 
	ORDER BY idclient, year;


-- III. Répartition par âge x sexe

SELECT DISTINCT civilite
FROM client;
-- Nous trouverons 6 valeurs unique pour la colonne "civilite": MADAME ; MONSIEUR ; Mme ; Mr ; madame ; monsieur. Nous essayons de mettre
-- juste seulement deux valeur "Homme" et "Femme" afin d'analyse la répartition âge et sexe

--D'abord, nous ajoutons une colonne "Age" qui se base sur l'année actuel et l'année de la colonne "datedenaissance"
ALTER TABLE client ADD COLUMN age INT; 
	UPDATE client SET age = EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM datenaissance); -- Calculer l'age de chaque client
--Calcul min;max et avg d'âge afin d'avoir une vision générale
SELECT MIN(age) as min_age, max(age) as max_value , avg(age) 
FROM client;

-- Nous ajoutons une colonne sex qui contient deux valeur unique  "Homme" ou "Femme". L'idée est de trouver des mot comme madame et monsieur et le remplace 	
ALTER TABLE client ADD COLUMN sex VARCHAR(10);
	UPDATE client SET sex = 
			CASE 
					WHEN civilite ilike '%madame%' or civilite ilike '%mme%' then 'femme'
					When civilite ilike '%monsieur%' or civilite ilike '%mr%' then 'homme'
					else 'unknown'
			END;
			

----Alors, on a décidé de remplacer les ages nulle ou <0 ou >100 par la moyenne des âges (55ans)
----Finalement, on a choisi de faire l'analyse sur les clients âgés de 18 jusqu'à 100 ans!

select count(age) from client where  age isnull or age < 0 or age > 100

--création d'une copie de la table client	
drop table IF EXISTS client_2;
create table client_test as select * from client;

--Remplacement des âges manquants par 55 ans, la moyenne 
UPDATE client_test set age = (case 
					when age isnull or age < 0 or age > 100 then 55
				 	else age
end);
--Elimination des clients avec âge<18 et âge>100 (0,13% de la table)
DELETE FROM client_test where age < 18 OR age > 100;


--Ajout d'une colonne qui nous donne les tranches d'âges 

ALTER TABLE client_test ADD tranche_age varchar(20);
UPDATE client_test set tranche_age = (case 
					when age BETWEEN 18 and 20 then '18 à 20 ans'
					when age>20 and age<=30 then '21 à 30 ans' 
					when age>30 and age<=40 then '31 à 40 ans' 
					when age>40 and age<=50 then '41 à 50 ans' 
					when age>50 and age<=60 then '51 à 60 ans' 
					when age>60 and age<=70 then '61 à 70 ans' 
					when age>70 and age<=80 then '71 à 80 ans' 
					when age>80 and age<=90 then '81 à 90 ans' 	
					when age>90 and age<=100 then '91 à 100 ans' 
	end);
select * from client_test

select sex ,tranche_age,count(idclient) from client_test
group by sex, tranche_age


-- ÉTUDE PAR MAGASIN -- 
SELECT magasin,ville,count(distinct client.idclient) as Nombre_Adherent
FROM client LEFT JOIN entete_ticket
				ON client.idclient = entete_ticket.idclient
			LEFT JOIN ref_magasin
				ON client.magasin = ref_magasin.codesociete
group by magasin,ville;

SELECT magasin, count(distinct client.idclient) as NombreClientActif_2016
FROM client LEFT JOIN entete_ticket
				ON client.idclient = entete_ticket.idclient
			LEFT JOIN ref_magasin
				ON client.magasin = ref_magasin.codesociete
			WHERE extract(year from tic_date ) = 2016
group by magasin;

SELECT magasin,count(distinct client.idclient) as NombreClientActif_2017
FROM client LEFT JOIN entete_ticket
				ON client.idclient = entete_ticket.idclient
			LEFT JOIN ref_magasin
				ON client.magasin = ref_magasin.codesociete
			WHERE extract(year from tic_date ) = 2017
group by magasin;

SELECT mag_code,sum(tic_totalttc)
FROM entete_ticket 
		WHERE extract(year from tic_date ) = 2016
group by mag_code;

SELECT mag_code,sum(tic_totalttc)
FROM entete_ticket 
	WHERE extract(year from tic_date ) = 2017
group by mag_code;

-- Nous avons créer une tableau qui contient 5 colonnes (magasi, ville;... )
CREATE TABLE store_stats (
  magasin VARCHAR(50),
  ville VARCHAR(50),
  Nombre_Adherent INT,
  NombreClientActif_2016 INT,
  NombreClientActif_2017 INT,
  Sales_2016 DECIMAL(10, 2),
  Sales_2017 DECIMAL(10, 2)
);

-- Faire la mise à jour de donné pour les colonnes 
INSERT INTO store_stats (magasin, ville, Nombre_Adherent)
SELECT magasin, ville, count(distinct client.idclient) as Nombre_Adherent
	FROM client LEFT JOIN entete_ticket
		ON client.idclient = entete_ticket.idclient
				LEFT JOIN ref_magasin
		ON client.magasin = ref_magasin.codesociete
group by magasin,ville;

UPDATE store_stats SET NombreClientActif_2016 = sub.NombreClientActif_2016
FROM (
 		SELECT magasin, count(distinct client.idclient) as NombreClientActif_2016
  			FROM client LEFT JOIN entete_ticket
  				ON client.idclient = entete_ticket.idclient
  						LEFT JOIN ref_magasin
  				ON client.magasin = ref_magasin.codesociete
  			WHERE extract(year from tic_date ) = 2016
  			group by magasin
) sub
WHERE store_stats.magasin = sub.magasin;

UPDATE store_stats SET NombreClientActif_2017 = sub.NombreClientActif_2017
FROM (
  		SELECT magasin,count(distinct client.idclient) as NombreClientActif_2017
  			FROM client LEFT JOIN entete_ticket
  				ON client.idclient = entete_ticket.idclient
		  				LEFT JOIN ref_magasin
		  		ON client.magasin = ref_magasin.codesociete
		  WHERE extract(year from tic_date ) = 2017
		  group by magasin
) sub
WHERE store_stats.magasin = sub.magasin;

UPDATE store_stats SET Sales_2016 = sub.Sales_2016
FROM (
  		SELECT mag_code,sum(tic_totalttc) as Sales_2016
  			FROM entete_ticket 
  				WHERE extract(year from tic_date ) = 2016
  		group by mag_code
) sub
WHERE store_stats.magasin = sub.mag_code;

UPDATE store_stats SET Sales_2017 = sub.Sales_2017
FROM (
  		SELECT mag_code,sum(tic_totalttc) as Sales_2017
  			FROM entete_ticket 
  				WHERE extract(year from tic_date ) = 2017
  		group by mag_code
) sub
WHERE store_stats.magasin = sub.mag_code;

--calculer l'évolution de ca et de nombre de client 
ALTER TABLE store_stats add evolution_client DECIMAL(10, 2);
ALTER TABLE store_stats add evolution_ca DECIMAL(10, 2); 

UPDATE store_stats
set evolution_client = (NombreClientActif_2017-NombreClientActif_2016)*100/NombreClientActif_2016 ; 
UPDATE store_stats
set evolution_ca = (Sales_2017-Sales_2016)*100/Sales_2016;

SELECT * from store_stats 




-- b. Distance CLIENT / MAGASIN
						  
						  
select * from client;


-- préparation de la table données gps ou on vas prendre le fichier csv et on vas le charger dans notre nouvelle table données GPS
drop table IF EXISTS donnees_GPS;
create table donnees_GPS 
(
	codeinsee varchar(10)  , 
	code_postal varchar(50)  ,
	commune varchar(50),
	latitude DOUBLE PRECISION,
	longitude DOUBLE PRECISION,
	geo_point_2d varchar(50)
);

COPY donnees_GPS FROM 'C:\Users\Public\projet_sql\Data_Transverse\Data_Transverse\correspondance-code-insee-code-postal.csv'  HEADER delimiter ';' null '';




--  cohérence entre les villes pour la table magasin  et communes pour la table donnees_GPS



select * from donnees_GPS


SELECT *
FROM ref_magasin
WHERE ville LIKE '%CEDEX%';

SELECT *
FROM ref_magasin
WHERE ville LIKE 'ST%';

SELECT *
FROM ref_magasin
WHERE ville LIKE '%SAINT%';

SELECT *
FROM donnees_GPS
WHERE commune LIKE '%SAINT%';

UPDATE donnees_GPS
SET commune = REPLACE(commune, ' ', '');

UPDATE ref_magasin
SET ville = REPLACE(ville, ' ', '');



UPDATE donnees_GPS
SET commune = REPLACE(commune, '-', '');

UPDATE ref_magasin
SET ville = REPLACE(ville, 'CEDEX', '');

UPDATE ref_magasin
SET ville = REPLACE(ville, 'ST', 'SAINT');

UPDATE ref_magasin
SET ville = REPLACE(ville, 'AixenProvence', 'AIXENPROVENCE');


-- Ajouter les colonnes pour les tables client et magasin 

ALTER TABLE client
ADD COLUMN latitude double precision  ;
ALTER TABLE client
ADD COLUMN longitude double precision  ;

select * from client ;

UPDATE client 
SET (latitude, longitude) = (donnees_GPS.latitude, donnees_GPS.longitude)
FROM donnees_GPS 
WHERE client.codeinsee = donnees_GPS.codeinsee;
ALTER TABLE ref_magasin
ADD COLUMN latitude double precision  ;
ALTER TABLE ref_magasin
ADD COLUMN longitude double precision  ;


UPDATE ref_magasin 
SET (latitude, longitude,idclient) = (donnees_GPS.latitude, donnees_GPS.longitud)
FROM donnees_GPS 
WHERE ref_magasin.ville = donnees_GPS.commune;

select * from ref_magasin;


-- creation de la table latitude_longitude ou on vas prendre les longi , lati de client et longi,lati de magasin avec l'id du client 
drop table IF EXISTS latitude_longitude;
CREATE TABLE latitude_longitude AS
SELECT ref_magasin.latitude AS magasin_latitude, ref_magasin.longitude AS magasin_longitude,
       client.latitude AS client_latitude, client.longitude AS client_longitude,
	   client.idclient as idclient
FROM ref_magasin
JOIN client
ON ref_magasin.codesociete= client.magasin;

select magasin_latitude, magasin_longitude, client_latitude, client_longitude from latitude_longitude;
select * from client




-- verifier si tout nos client on donnée les villes sionon on va avoir des null dans nos colonnes longi , lati de client

select * from latitude_longitude

SELECT *from latitude_longitude where 
magasin_latitude is null or  magasin_longitude is null or  client_latitude is null or client_longitude is null ;


-- supprimer les colonnes longitude et latitude de client qui sont null 

DELETE FROM latitude_longitude WHERE magasin_latitude is null or  magasin_longitude is null or  client_latitude is null or client_longitude is null ;

-- ajouter une nouvelle colonne distance 
ALTER TABLE latitude_longitude ADD COLUMN distance double precision;

-- verifier si nos colonnes est dans l'intevalle correcte 
SELECT magasin_latitude, magasin_longitude, client_latitude, client_longitude
FROM latitude_longitude
WHERE magasin_latitude < -90 OR magasin_latitude > 90 OR magasin_longitude < -180 OR magasin_longitude > 180
   OR client_latitude < -90 OR client_latitude > 90 OR client_longitude < -180 OR client_longitude > 180;



-- fonction pour calculer la distance entre 2 points 


CREATE OR REPLACE FUNCTION haversine_distance(magasin_latitude double precision, magasin_longitude double precision, client_latitude double precision, client_longitude double precision)
    RETURNS double precision
    LANGUAGE SQL AS
    $$
        SELECT CASE
            WHEN magasin_latitude = client_latitude AND magasin_longitude = client_longitude THEN 0
            ELSE 6371 * acos(cos(radians(magasin_latitude)) * cos(radians(client_latitude)) * cos(radians(client_longitude) - radians(magasin_longitude)) + sin(radians(magasin_latitude)) * sin(radians(client_latitude)))::double precision
        END;
    $$;

-- tester la fonction avec les colonnes de notre table jointure 
SELECT magasin_latitude, magasin_longitude, client_latitude, client_longitude, haversine_distance(magasin_latitude, magasin_longitude, client_latitude, client_longitude) as distance
FROM latitude_longitude ; 

-- mise a jour de notre table latitude_longitude avec la colonne distance 
 UPDATE latitude_longitude SET distance = haversine_distance(magasin_latitude, magasin_longitude, client_latitude, client_longitude);



    select * from latitude_longitude
	
	
-- Constituer une représentation (tableau ou graphique --> au choix) représentant le nombre de client par
-- distance : 0 à 5km, 5km à 10km, 10km à 20km, 20km à 50km, plus de 50km


-- ajouter une colonne distance_range dans notre table latitude_longitude


ALTER TABLE latitude_longitude
ADD COLUMN distance_range  text  ;

ALTER TABLE latitude_longitude
DROP COLUMN distance_range;


UPDATE latitude_longitude
SET distance_range = subq.distance_range
FROM (
    SELECT
        idclient,
        CASE
            WHEN distance BETWEEN 0 AND 5 THEN '0-5 km'
            WHEN distance BETWEEN 5 AND 10 THEN '5-10 km'
            WHEN distance BETWEEN 10 AND 20 THEN '10-20 km'
            WHEN distance BETWEEN 20 AND 50 THEN '20-50 km'
            WHEN client_latitude IS NULL THEN 'inconnue'
            ELSE 'Plus de 50 km'
        END AS distance_range
    FROM latitude_longitude
) AS subq
WHERE latitude_longitude.idclient = subq.idclient;

select * from latitude_longitude
		
-- 	calculer le pourcentage de distance range par rapport au nombre totale des client 
	SELECT
    CASE
        WHEN distance BETWEEN 0 AND 5 THEN '0-5 km'
        WHEN distance BETWEEN 5 AND 10 THEN '5-10 km'
        WHEN distance BETWEEN 10 AND 20 THEN '10-20 km'
        WHEN distance BETWEEN 20 AND 50 THEN '20-50 km'
		when client_latitude is null then 'inconnue'
        ELSE 'Plus de 50 km'
    END AS distance_range,
    COUNT(idclient) AS client_count,
    COUNT(idclient) * 100.0 / (SELECT COUNT(idclient) FROM latitude_longitude) AS client_percentage
FROM
    latitude_longitude
GROUP BY
    CASE
        WHEN distance BETWEEN 0 AND 5 THEN '0-5 km'
        WHEN distance BETWEEN 5 AND 10 THEN '5-10 km'
        WHEN distance BETWEEN 10 AND 20 THEN '10-20 km'
        WHEN distance BETWEEN 20 AND 50 THEN '20-50 km'
		when client_latitude is null then 'inconnue'
        ELSE 'Plus de 50 km'
    END;

	
	
--a. ETUDE PAR UNIVERS
--Constituer un histogramme N-2 / N-1 évolution du CA par univers
--On cherche la somme des CA par univers de 2016 et 2017 pour comparer l'évolution du CA du N-2 au N-1
select codeunivers, sum(total) as CA, extract(year from tic_date) as year
from entete_ticket inner join lignes_ticket
on entete_ticket.idticket = lignes_ticket.idticket
inner join ref_article on lignes_ticket.idarticle = ref_article.codearticle
group by codeunivers, year;



--b.TOP PAR UNIVERS
--Afficher le top 5 des familles les plus rentable par univers (en fonction de la marge obtenu) (tableau ou graphique -> au choix)
--Après avoir calculé la marge, nous avons constaté que l'univers U1 est le seul univers avec plus de 5 familles.
--C'est pourquoi nous avons décidé de créer 2 tables différentes : l'une contenant uniquement U1 et l'autre contenant le reste.
--Enfin nous avons rejoindre 2 tables afin d'obtenir le résultat
create table U1 as
select codeunivers, codefamille, sum(margesortie) as marge
from lignes_ticket inner join ref_article
on lignes_ticket.idarticle = ref_article.codearticle
where codeunivers = 'U1'
group by codefamille, codeunivers
order by marge desc limit 5;
create table univers as
select codeunivers, codefamille, sum(margesortie) as marge
from lignes_ticket inner join ref_article
on lignes_ticket.idarticle = ref_article.codearticle
where codeunivers != 'U1'
group by codefamille, codeunivers
order by marge;
select * from U1
union
select * from univers;


