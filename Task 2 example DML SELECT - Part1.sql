/*If I use several approaches to solve the same task the majority of comments I use in the first query option,
adding some extra comments in other approaches only for additional explanation.*/
---------------------------------------------------------------------------------------------------------
/*Part 1. Task 1. All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
--
To main table film we need to add the information from tables film_category and category 
to specify the category, while release year and rate are present in the main table film.*/
---------------------------------------------------------------------------------------------------------
--Join option
SELECT fi.title 
FROM       public.film          fi
INNER JOIN public.film_category fcat ON fcat.film_id    = fi.film_id 
INNER JOIN public.category      cat  ON cat.category_id = fcat.category_id 
WHERE LOWER(cat.name) = 'animation'         AND --looking for required category
      fi.release_year BETWEEN 2017 AND 2019 AND --looking for required period
      fi.rental_rate  > 1                       --looking for required rate
ORDER BY fi.title;								--sorting
---------------------------------------------------------------------------------------------------------
--Subquery option
SELECT fi.title 
FROM public.film fi
WHERE EXISTS (--looking for animation movies
	           SELECT fcat.film_id 
			   FROM       public.film_category fcat
			   INNER JOIN public.category      cat  ON cat.category_id = fcat.category_id 
			   WHERE LOWER(cat.name)   = 'animation'  AND
				     fi.film_id        = fcat.film_id) AND 
      fi.release_year BETWEEN 2017 AND 2019 AND 
      fi.rental_rate > 1
ORDER BY fi.title;
---------------------------------------------------------------------------------------------------------
--CTE option
WITH animation_films AS (--looking for animation movies
SELECT fcat.film_id 
FROM       public.film_category fcat
INNER JOIN public.category      cat  ON cat.category_id = fcat.category_id 
WHERE LOWER(cat.name) = 'animation'
)
SELECT fi.title 
      FROM public.film     fi
INNER JOIN animation_films anfi ON fi.film_id = anfi.film_id
WHERE fi.release_year BETWEEN 2017 AND 2019 AND 
      fi.rental_rate > 1
ORDER BY fi.title;
---------------------------------------------------------------------------------------------------------
/*Conclusion:
A subquery is preferable in this case because there is no need to reuse the result, 
which is the main advantage of using a CTE. 
Additionally, all the required information is contained within a single table, 
so there is no need to join additional tables.*/
---------------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------------
/*Part 1. Task 2. The revenue earned by each rental store since March 2017 
(columns: address and address2 – as one column, revenue)
--
Here we need to add several tables to be able to link the information from main required tables 
address and payment. Revenue is calculated as the total of all payment amounts.*/
---------------------------------------------------------------------------------------------------------
--Join option
SELECT adr.address || ' ' || COALESCE(adr.address2, '') AS shop_addr,  --concatenating shop addresses
       SUM(pay.amount)                                  AS revenue     --calculating payments total
FROM       public.payment   pay 
INNER JOIN public.rental    rnt ON rnt.rental_id    = pay.rental_id 
INNER JOIN public.inventory inv ON inv.inventory_id = rnt.inventory_id 
INNER JOIN public.store     st  ON inv.store_id     = st.store_id 
INNER JOIN public.address   adr ON st.address_id    = adr.address_id 
WHERE pay.payment_date >= '2017-03-01' 								   --looking for required period
GROUP BY adr.address || ' ' || COALESCE(adr.address2, '');
---------------------------------------------------------------------------------------------------------
--Subquery option
SELECT addresses.shop_addr AS shop_addr, 
       SUM(pay.amount)     AS revenue
FROM       public.payment pay 
INNER JOIN (--extracting and concatenating shop addresses
            SELECT adr.address || ' ' || COALESCE(adr.address2, '') AS shop_addr,
			       rnt.rental_id 
			FROM       public.address   adr
			INNER JOIN public.store     st  ON st.address_id    = adr.address_id
			INNER JOIN public.inventory inv ON inv.store_id     = st.store_id 
			INNER JOIN public.rental    rnt ON inv.inventory_id = rnt.inventory_id) AS addresses ON addresses.rental_id = pay.rental_id
WHERE pay.payment_date >= '2017-04-01' 
--accepted if >='2017-03-01' 
GROUP BY addresses.shop_addr;
---------------------------------------------------------------------------------------------------------
--CTE option
WITH addresses AS (--extracting and concatenating shop addresses
SELECT adr.address || ' ' || COALESCE(adr.address2, '') AS shop_addr,
       rnt.rental_id 
FROM       public.address   adr
INNER JOIN public.store     st  ON st.address_id    = adr.address_id
INNER JOIN public.inventory inv ON inv.store_id     = st.store_id 
INNER JOIN public.rental    rnt ON inv.inventory_id = rnt.inventory_id
)
SELECT add.shop_addr   AS shop_addr, 
       SUM(pay.amount) AS revenue
FROM       public.payment   pay 
INNER JOIN addresses        add ON add.rental_id = pay.rental_id
WHERE pay.payment_date >= '2017-03-01'
GROUP BY add.shop_addr;
---------------------------------------------------------------------------------------------------------
/*Conclusion:
Join option is preferable in this case because the logic of this query is pretty straightforward 
and all the tables are connected subsequently via foreigh keys. 
Moreover we need the results from both payment and address tables, so according to the logic 
that all tables containing required data should be included in the main query, this approach looks good. 
Additionally, there is no need to reuse the result, which is the main advantage of using a CTE.*/
---------------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------------
/*Part 1. Task 3. Top-5 actors by number of movies (released since 2015) they took part in 
(columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
--
The task can be interpreted in 2 different ways because there is the same number of films for actors
on the positions from 4 to 7. So, limiting the result strictly by 5 values we may loose required values. 
However, 2 different approaches are considered below.*/
---------------------------------------------------------------------------------------------------------
--Join option
--This query limits the result to exactly 5 actors
SELECT act.first_name, 
       act.last_name, 
       COUNT(DISTINCT filact.film_id) AS number_of_movies --counting number of films
FROM       public.actor      act
INNER JOIN public.film_actor filact ON act.actor_id   = filact.actor_id 
INNER JOIN public.film       fi     ON filact.film_id = fi.film_id 
WHERE fi.release_year >= 2015                       --looking for required period
GROUP BY act.actor_id 
ORDER BY COUNT(DISTINCT filact.film_id) DESC        --sorting
LIMIT 5;									        --limiting strictly 5 rows	
---------------------------------------------------------------------------------------------------------
--Subquery option
/*This query returns actors whose rank is within the top 5 by number of films
(I simulate dense_rank window function behavior)*/
SELECT act.first_name, 
       act.last_name, 
       COUNT(fi.film_id) AS number_of_movies
FROM       public.actor      act
INNER JOIN public.film_actor filact ON act.actor_id   = filact.actor_id 
INNER JOIN public.film       fi     ON filact.film_id = fi.film_id 
WHERE fi.release_year >= 2015
GROUP BY act.actor_id 
HAVING COUNT(fi.film_id) IN (--extracting 5 maximal movies quantities
							 SELECT DISTINCT COUNT(filact.film_id) AS top_count 
							 FROM       public.film_actor filact  
							 INNER JOIN public.film       fi     ON filact.film_id = fi.film_id 
							 WHERE fi.release_year >= 2015
							 GROUP BY filact.actor_id 
							 ORDER BY top_count DESC
							 LIMIT 5)
ORDER BY number_of_movies DESC;
---------------------------------------------------------------------------------------------------------
--CTE option
/*This query also returns actors whose rank is within the top 5 by number of films
(I simulate dense_rank window function behavior)*/
WITH film_number AS (
SELECT act.first_name, 
       act.last_name, 
       COUNT(fi.film_id) AS number_of_movies
FROM       public.actor      act
INNER JOIN public.film_actor filact ON act.actor_id   = filact.actor_id 
INNER JOIN public.film       fi     ON filact.film_id = fi.film_id 
WHERE fi.release_year >= 2015
GROUP BY act.actor_id
)
SELECT fnum.first_name, 
       fnum.last_name, 
       fnum.number_of_movies 
FROM film_number fnum
WHERE fnum.number_of_movies IN (--extracting 5 maximal movies quantities
						  		SELECT DISTINCT number_of_movies
                          		FROM film_number
                          		ORDER BY number_of_movies DESC
                          		LIMIT 5)
ORDER BY fnum.number_of_movies DESC;
---------------------------------------------------------------------------------------------------------
/*Conclusion:
I personally consider that the logic of retrieving actors with 5 highest ranks is more suitable here. 
According to this logic the CTE option is optimal, because it reuses the same subquery.
This approach simplifies the query structure and enhances readability and maintainability.*/
---------------------------------------------------------------------------------------------------------                         
                         
          
  


---------------------------------------------------------------------------------------------------------
/*Part 1. Task 4. Number of Drama, Travel, Documentary per year 
(columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), 
sorted by release year in descending order. Dealing with NULL values is encouraged)
--
For each release year we count films in specific categories.*/
---------------------------------------------------------------------------------------------------------
--Join option
/*In this task I use the only one approach with joins using FILTER clause, 
which is an elegant and straightforward solution that simplifies the query structure. 
I've found it in the section with additional information for this course 
and have got an opportunity to apply it right now. Using subqueries or CTEs is redundant here, 
because all the tables are connected subsequently via foreigh keys.
The simpliest and the most beautiful way in my opinion.
There is no need to deal with null values because count() processes everything correctly.*/
SELECT fi.release_year, 
       COUNT(fi.film_id) FILTER (WHERE LOWER(cat.name) = 'drama')       AS number_of_drama_movies,      --lookind for quantity of Drama using filtering condition
       COUNT(fi.film_id) FILTER (WHERE LOWER(cat.name) = 'travel')      AS number_of_travel_movies,  	--lookind for quantity of Travel using filtering condition
       COUNT(fi.film_id) FILTER (WHERE LOWER(cat.name) = 'documentary') AS number_of_documentary_movies --lookind for quantity of Documentary using filtering condition
FROM       public.film_category fcat
INNER JOIN public.film          fi   ON fi.film_id       = fcat.film_id 
INNER JOIN public.category      cat  ON fcat.category_id = cat.category_id
GROUP BY fi.release_year
ORDER BY fi.release_year DESC;   													                    --sorting
---------------------------------------------------------------------------------------------------------


