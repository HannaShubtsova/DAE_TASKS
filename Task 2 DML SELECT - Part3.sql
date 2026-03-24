---------------------------------------------------------------------------------------------------------
/*Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
The task can be interpreted in various ways, and here are a few options:
V1: gap between the latest release_year and current year per each actor;
V2: gaps between sequential films per each actor;

It would be plus if you could provide a solution for each interpretation

--
V1. Firstly in CTE we are looking for the latest (maximal) movie release year for every actor 
and find the difference between this year and current year. This stage provides us with the information 
about the gap between the latest release year and current year per each actor. 
Then we find maximal of this gaps and looking for actors whose gap between last release year 
and current year is equal to the found maximal gap.
--
V2. According to my logic in CTEs we are subsequently looking for:
- all the films for each actor and their release years;
- ordered list of movies release years per each actor;
- maximal gap between every 2 sequential films per each actor.
Then in subquery we retwieve maximal gap among all of actors and in the main query look for actors 
whose maximal gap between every 2 sequential films is equal to the found maximal gap.*/
---------------------------------------------------------------------------------------------------------
--V1. Gap between the latest release_year and current year per each actor
WITH gaps AS (--looking for gaps between the latest release year and current year for each actor
SELECT act.actor_id, 
       act.first_name, 
       act.last_name, 
       EXTRACT(YEAR FROM current_date) - MAX(fi.release_year) AS gap
FROM       public.actor      act
INNER JOIN public.film_actor fact ON act.actor_id = fact.actor_id
INNER JOIN public.film       fi   ON fi.film_id   = fact.film_id
GROUP BY act.actor_id, 
         act.first_name, 
         act.last_name
)
SELECT ga.actor_id,--looking for actors having maximal gap among all the actors
       ga.first_name, 
       ga.last_name, 
       ga.gap
FROM gaps ga
WHERE ga.gap = ( --looking for maximal gap among all the actors
				SELECT MAX(gap) 
				FROM gaps);
---------------------------------------------------------------------------------------------------------
--V2: gaps between sequential films per each actor
/*In this case I'm looking for all the gaps between sequential fimls per each actor 
 and retrieve the biggest of them*/
WITH actor_film_list AS (--looking for all the films for each actor and their release years
SELECT fact.actor_id,
       fi.film_id,
       fi.release_year
FROM       public.film_actor fact
INNER JOIN public.film       fi   ON fact.film_id = fi.film_id
),
     actor_year_list AS (--looking for ordered list of movies release years per each actor
SELECT afl1.actor_id,
       afl1.release_year      AS prev_release_year,
       MIN(afl2.release_year) AS curr_release_year
FROM      actor_film_list afl1
LEFT JOIN actor_film_list afl2 ON afl1.actor_id = afl2.actor_id 
WHERE afl2.release_year > afl1.release_year
GROUP BY afl1.actor_id, 
         afl1.release_year
ORDER BY afl1.actor_id, 
         afl1.release_year
),
     actor_max_gap AS (-- looking for maximal gap between every 2 sequential films per each actor
SELECT ayl.actor_id, 
       MAX(ayl.curr_release_year - ayl.prev_release_year) AS max_gap
FROM actor_year_list AS ayl
GROUP BY ayl.actor_id
)
SELECT act.actor_id,--looking for actors whose maximal gap between every 2 sequential films is equal to the aximal gap among all actors
       act.first_name, 
       act.last_name, 
       ag.max_gap
FROM       actor_max_gap ag 
INNER JOIN public.actor  act ON act.actor_id = ag.actor_id
WHERE ag.max_gap = (-- looking for maximal gap among all of actors
					SELECT MAX(max_gap)
					FROM actor_max_gap);
---------------------------------------------------------------------------------------------------------
/*Conclusion:
The CTE option is optimal here, because the solution reuses the same subqueries.
This approach simplifies the query structure and enhances readability and maintainability.*/
---------------------------------------------------------------------------------------------------------  
				

-- v3. 
-- Actors/Actresses who didn't act for a long period of time until now.
-- Let us select Actors/Actresses who didn't act for 5 years till now or more.

WITH actor_ywf AS 
	(SELECT 	a.first_name ||' '||a.last_name actor_full_name,
				a.actor_id ,
				min(date_part('year', CURRENT_DATE) - f.release_year) AS years_wo_films
	FROM actor a 
	INNER JOIN film_actor fa 
	ON a.actor_id = fa.actor_id 
	INNER JOIN film f 
	ON fa.film_id = f.film_id
	GROUP BY a.actor_id 
	ORDER BY min(date_part('year', CURRENT_DATE) - f.release_year) DESC) 
SELECT a.actor_full_name, a.years_wo_films
FROM actor_ywf a 
WHERE a.years_wo_films =
		(SELECT max(a1.years_wo_films)
		FROM actor_ywf a1) ;


-- V4. Actors/Actresses that had the biggest break between their films.
/* Note that here we take only Actors/Actresses who had at least 2 films. */

-- CTE was used to ease the understanding of the whole script.
-- In CTE we join tables film and actor with the help of bridge table film_actor.

WITH 
actors_films AS
		(SELECT a.first_name , a.last_name , a.actor_id , f.film_id , f.title , f.release_year
		FROM actor a
		INNER JOIN film_actor fa
		ON a.actor_id= fa.actor_id
		INNER JOIN film f
		ON fa.film_id = f.film_id),

actor_ywf as
	(SELECT af.first_name, af.last_name, af.actor_id, max(diff_btw_films) AS years_wo_films
	 FROM 
		(SELECT af1.first_name, 
				af1.last_name, 
				af1.actor_id, 
				af1.film_id, 
				min(af2.release_year - af1.release_year) AS diff_btw_films
		-- Diff_btw_films is a number of years passed between two sequential films of one actor.
		-- Two sequential films released in one year are not taken into account, because we assume that there was no interval between them.				
		FROM actors_films af1
		INNER JOIN actors_films af2
		ON af1.actor_id=af2.actor_id
		WHERE af1.release_year < af2.release_year
		GROUP BY af1.first_name, af1.last_name, af1.actor_id, af1.film_id
		ORDER BY min(af2.release_year - af1.release_year) DESC) AS af
GROUP BY af.first_name, af.last_name, af.actor_id
-- Group by actors and select max(diff_btw_films) to extract the actor who had the biggest difference between all their films.
ORDER BY max(diff_btw_films) DESC)

SELECT a.first_name, a.last_name, a.years_wo_films
FROM actor_ywf a
WHERE  a.years_wo_films = 
						(SELECT max(years_wo_films)
						FROM actor_ywf);
					

		
					
					
-- v5: 
-- ActorData: actors and their acting years (the years of difference between the release of their first and last film). 
-- I selected rows from ActorData with the minimum values of acting_years.
WITH ActorData AS (
SELECT
	a.first_name,
	a.last_name,
	(MAX(f.release_year) - MIN(f.release_year)) AS acting_years
FROM
	actor a
INNER JOIN film_actor fa ON
	fa.actor_id = a.actor_id
INNER JOIN film f ON
	f.film_id = fa.film_id
GROUP BY
	a.actor_id,
	a.first_name,
	a.last_name
)
SELECT
	actdata.first_name,
	actdata.last_name,
	actdata.acting_years
FROM
	ActorData actdata
WHERE
	actdata.acting_years = (
	SELECT
		MIN(acting_years)
	FROM
		ActorData);

	
-- V6:
-- This is different from v1, because in v2 by acting years I mean the count of different years in which the actor/actress had a movie released.
WITH ActorData AS (
SELECT
	a.first_name,
	a.last_name,
	count (DISTINCT f.release_year) acting_years
FROM
	actor a
INNER JOIN film_actor fa ON
	fa.actor_id = a.actor_id
INNER JOIN film f ON
	f.film_id = fa.film_id
GROUP BY
	a.actor_id,
	a.first_name,
	a.last_name
)
SELECT
	actdata.first_name,
	actdata.last_name,
	actdata.acting_years
FROM
	ActorData actdata
WHERE
	actdata.acting_years = (
	SELECT
		MIN(acting_years)
	FROM
		ActorData);

				