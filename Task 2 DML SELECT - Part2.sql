---------------------------------------------------------------------------------------------------------
/*Part 2. Task 1. Which three employees generated the most revenue in 2017? 
They should be awarded a bonus for their outstanding performance. 
Assumptions: 
-staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
-if staff processed the payment then he works in the same store; 
-take into account only payment_date
--
Comment on this task in Teams: 'Let's use store_id from staff' (The DB has some discrepancies:
it was noticed that we have the situation that one staff member has the same maximal dates of payments 
in both of stores. The order of payment_id field doesn't correspond to the order of payment dates. 
So it's impossible to indicate which store the staff worked in (the last one).)
In this task firstly in the subquery we are looking for totals of all payment amounts 
processed by each worker in 2017. Then we cut out all but 3 greatest of them. In the main query we add 
to retrieved staff members store they worked in.*/
---------------------------------------------------------------------------------------------------------
--v1
SELECT st.staff_id,
	   st.first_name || ' ' || st.last_name AS staff_name,
       st.store_id, 
       toprev.total_revenue
FROM public.staff st 
INNER JOIN (--looking for 3 employees with maximal payments totals
			SELECT pay.staff_id,
			       SUM(pay.amount) AS total_revenue             --calculating payments total
			FROM public.payment pay 
			WHERE EXTRACT(YEAR FROM pay.payment_date) = 2017    --looking for required year
			GROUP BY pay.staff_id 
			ORDER BY SUM(pay.amount) DESC                       --sorting
			LIMIT 3) AS toprev ON toprev.staff_id = st.staff_id --limiting strictly 5 rows
ORDER BY toprev.total_revenue DESC;								--sorting
---------------------------------------------------------------------------------------------------------
/*Conclusion:
The subquery option is ideal for this task, as it allows us to identify the top three employees 
with the highest revenue totals in 2017 before joining the staff table to add their respective store information.*/
---------------------------------------------------------------------------------------------------------                         


--v2
/* Note that if 2 staff members made the same revenue, 2 of them will be displayed. 
   CTE was used since there is a rather complicated part of the script recurrent for 2 times.
   CTE will ease the understanding of the whole script. */

-- SELECT store_id, staff_id and staff_id accumulated revenue for year 2017.
WITH store_staff_revenue AS 
		(SELECT s2.store_id , s2.staff_id , s2.first_name ||' '||s2.last_name AS staff_fn, staff_revenue.staff_rev
		FROM staff s2 
		INNER JOIN (
			SELECT s.staff_id , sum(p.amount) AS staff_rev
			FROM staff s 
			INNER JOIN payment p
			ON s.staff_id = p.staff_id 
			WHERE p.payment_date BETWEEN '2017-01-01 00:00:00' and '2017-12-31 23:59:59'
			GROUP BY s.staff_id) staff_revenue
		ON s2.staff_id = staff_revenue.staff_id)
		
-- SELECT store_id, staff_id, staff_rev with the higherst staff_rev for each store_id	
SELECT ssr1.store_id, ssr1.staff_fn, ssr1.staff_rev
FROM store_staff_revenue ssr1
WHERE exists (	
			SELECT ssr2.store_id, max(ssr2.staff_rev)
			FROM store_staff_revenue ssr2
			GROUP BY ssr2.store_id
			HAVING ssr1.staff_rev = max(ssr2.staff_rev));

	

		
-- v3:
-- StaffRevenue: for each store the revenues made by each staff in 2017. 
-- MaxStoreRevenue: the maximum revenue of each store.
-- By joining StaffRevenue and MaxStoreRevenue, only the records with the maximum revenue remained.
   
WITH StaffRevenue AS (
SELECT
	st.store_id,
	st.staff_id,
	CONCAT(st.first_name, ' ', st.last_name) AS staff_name,
	SUM(p.amount) AS total_revenue
FROM
	staff st
JOIN payment p ON
	st.staff_id = p.staff_id
JOIN rental r ON
	p.rental_id = r.rental_id
WHERE
	EXTRACT(YEAR
FROM
	p.payment_date) = 2017
GROUP BY
	st.store_id,
	st.staff_id,
	staff_name
),
MaxStoreRevenue AS (
SELECT
	store_id,
	MAX(total_revenue) AS max_revenue
FROM
	StaffRevenue
GROUP BY
	store_id
)
SELECT
	(
	SELECT
		concat(a.address, '', a.address2)
	FROM
		address a
	INNER JOIN store s ON
		s.store_id = a.address_id
		AND s.store_id = sr.store_id
) AS address,
	sr.staff_name,
	sr.total_revenue
FROM
	StaffRevenue sr
JOIN MaxStoreRevenue maxrev ON
	sr.store_id = maxrev.store_id
WHERE
	sr.total_revenue = maxrev.max_revenue;



-- v4
-- The same as v1, but without using CTE-s. The max revenue is calculated in a subquery of the having clause.
SELECT
	(
	SELECT
		concat(a.address, '', a.address2)
	FROM
		address a
	INNER JOIN store s ON
		s.store_id = a.address_id
		AND s.store_id = st.store_id
) AS address,	
    CONCAT(st.first_name, ' ', st.last_name) AS staff_name,
	SUM(p.amount) AS total_revenue
FROM
	staff st
JOIN payment p ON
	st.staff_id = p.staff_id
JOIN rental r ON
	p.rental_id = r.rental_id
WHERE
	EXTRACT(YEAR
FROM
	p.payment_date) = 2017
GROUP BY
	st.store_id,
	st.staff_id,
	staff_name
HAVING
	SUM(p.amount) = (
	SELECT
		MAX(total_revenue)
	FROM
		(
		SELECT
			st.store_id,
			st.staff_id,
			SUM(p.amount) AS total_revenue
		FROM
			staff st
		JOIN payment p ON
			st.staff_id = p.staff_id
		JOIN rental r ON
			p.rental_id = r.rental_id
		WHERE
			EXTRACT(YEAR
		FROM
			p.payment_date) = 2017
		GROUP BY
			st.store_id,
			st.staff_id) AS MaxStoreRevenue
	WHERE
		MaxStoreRevenue.store_id = st.store_id
    );




---------------------------------------------------------------------------------------------------------
/*Part 2. Task 2. Which 5 movies were rented more than others (number of rentals), 
and what's the expected age of the audience for these movies? 
To determine expected age please use 'Motion Picture Association film rating system.
--
The meaning and age restrictions for each rating group are provided below.
The task can be interpreted in 2 different ways because there is the same number of rentals for films 
on the positions from 3 to 7. So, limiting the result strictly by 5 values we may loose required values. 
However, 2 different approaches are considered below.*/
---------------------------------------------------------------------------------------------------------
--Join option
--This query limits the result to exactly 5 movies
SELECT fi.film_id, 
       fi.title, 
       fi.rating, 
	   CASE 							 --explaining each rating group
	       WHEN fi.rating = 'G'     THEN 'General audiences. Suitable for all ages.'
	       WHEN fi.rating = 'PG'    THEN 'Parental Guidance Suggested. 8+, parental guidance suggested, especially for younger children.'
	       WHEN fi.rating = 'PG-13' THEN 'Parents Strongly Cautioned. 13+.'
	       WHEN fi.rating = 'R'     THEN 'Restricted. 17+, under 17 requires adult supervision.'
	       WHEN fi.rating = 'NC-17' THEN 'Adults Only. 18+, no one 17 or under admitted.'

	   END               AS rating_description,
       COUNT(fi.film_id) AS rental_count --counting rentals
FROM       public.rental    ren 
INNER JOIN public.inventory inv ON inv.inventory_id = ren.inventory_id 
INNER JOIN public.film      fi  ON fi.film_id       = inv.film_id 
GROUP BY fi.film_id, 
		 fi.title, 
		 fi.rating
ORDER BY rental_count DESC 				 --sorting
LIMIT 5; 								 --limiting strictly 5 rows
---------------------------------------------------------------------------------------------------------
--CTE option
/*This query returns movies which rank is within the top 5 by number of rentals
(I simulate dense_rank window function behavior)*/
WITH rental_number AS (--counting rentals
SELECT fi.film_id, 
       fi.title, 
       fi.rating, 
       COUNT(fi.film_id) AS rental_count
FROM       public.rental    ren 
INNER JOIN public.inventory inv ON inv.inventory_id = ren.inventory_id 
INNER JOIN public.film      fi  ON fi.film_id       = inv.film_id 
GROUP BY fi.film_id, 
         fi.title, 
         fi.rating
)
SELECT rnum.film_id, 
       rnum.title, 
       rnum.rating, 
	   CASE 
	       WHEN rnum.rating = 'G'     THEN 'General audiences. Suitable for all ages.'
	       WHEN rnum.rating = 'PG'    THEN 'Parental Guidance Suggested. 8+, parental guidance suggested, especially for younger children.'
	       WHEN rnum.rating = 'PG-13' THEN 'Parents Strongly Cautioned. 13+.'
	       WHEN rnum.rating = 'R'     THEN 'Restricted. 17+, under 17 requires adult supervision.'
	       WHEN rnum.rating = 'NC-17' THEN 'Adults Only. 18+, no one 17 or under admitted.'
	   END AS rating_description,
	   rnum.rental_count
FROM  rental_number rnum
WHERE rnum.rental_count IN (--extracting 5 maximal rental quantities
							SELECT DISTINCT rental_count
							FROM rental_number
							ORDER BY rental_count DESC
							LIMIT 5)
ORDER BY rental_count DESC;
---------------------------------------------------------------------------------------------------------
/*Conclusion:
I personally consider that the logic of retrieving movies with 5 highest ranks is more suitable here. 
According to this logic the CTE option is optimal, because it reuses the same subquery.
This approach simplifies the query structure and enhances readability and maintainability.*/
---------------------------------------------------------------------------------------------------------    

