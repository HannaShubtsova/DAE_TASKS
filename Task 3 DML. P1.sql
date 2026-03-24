-- Task 1 Part 1
-- Choose your top-3 favorite movies and add them to the 'film' table. Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.

/* The INSERT statement inserts 3 new records to the film table, with the required values entered. */
INSERT INTO public.film (title, language_id, rental_duration, rental_rate)
SELECT 	newfilm.title,
		newfilm.language_id,
		newfilm.rental_duration,
		newfilm.rental_rate
FROM (VALUES
		(
			'Lord of the Rings',
			(
				SELECT l.language_id
				FROM public."language" l
				WHERE l."name" = 'English'
			),
			7,
			4.99
		), (
			'Das Boot',
			(
				SELECT l.language_id
				FROM public."language" l
				WHERE l."name" = 'German'
			),
			14,
			9.99
		), (
			'12 Angry Men',
			(
				SELECT l.language_id
				FROM public."language" l
				WHERE l."name" = 'English'
			),
			21,
			19.99
		)
	) AS newfilm (title, language_id, rental_duration, rental_rate)
WHERE NOT EXISTS (					-- The WHERE NOT EXISTS clause is corrected. Currently the film table only contains movies with distinct titles.
	SELECT 1
	FROM public.film f 
	WHERE f.title = newfilm.title 	-- If in the future two movies with the same title (for example different language copies) would be added, additional filters would have to be defined.
	);

-- Task 1 Part 2
-- Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).

/* The INSERT statement inserts 6 new records to the actor table, with the required values entered. */
INSERT INTO public.actor (first_name, last_name)
SELECT 	newactor.first_name,
		newactor.last_name
FROM (VALUES 	
		('VIGGO', 'MORTENSEN'),
		('ELIJAH', 'WOOD'),
		('JURGEN', 'PROCHNOW'),
		('HUBERTUS', 'BENGSCH'),
		('HENRY', 'FONDA'),
		('MARTIN', 'BALSAM')
	) AS newactor (first_name, last_name)
WHERE NOT EXISTS (										-- The WHERE NOT EXISTS clause is corrected. Currently there is a duplicate actor name in the actor table (in original data).
	SELECT 1
	FROM public.actor a 
	WHERE 	a.first_name 	= newactor.first_name AND	-- This statement will not allow an actor with a name that already exists in the table to be added!
			a.last_name 	= newactor.last_name
	);

/* 
 * We manually have to make the connections in the bridge table film_actor, the INSERT statement has an array of subqueries to insert every new record.
 * The statements SELECT the actor_id from the actor table based on actor name, and the film_id from the film table based on film title. 
 */
INSERT INTO public.film_actor (actor_id, film_id)
SELECT 	new_film_actor.actor_id,
		new_film_actor.film_id
FROM (VALUES 	
		(
			(	
			SELECT a.actor_id 
			FROM actor a
			WHERE a.first_name = 'VIGGO' AND a.last_name = 'MORTENSEN'
			),
			(
			SELECT f.film_id 
			FROM film f
			WHERE UPPER(f.title) = 'LORD OF THE RINGS'
			)
		),
		(
			(	
			SELECT a.actor_id 
			FROM actor a
			WHERE a.first_name = 'ELIJAH' AND a.last_name = 'WOOD'
			),
			(
			SELECT f.film_id 
			FROM film f
			WHERE UPPER(f.title) = 'LORD OF THE RINGS'
			)
		),
		(
			(	
			SELECT a.actor_id 
			FROM actor a
			WHERE a.first_name = 'JURGEN' AND a.last_name = 'PROCHNOW'
			),
			(
			SELECT f.film_id 
			FROM film f
			WHERE UPPER(f.title) = 'DAS BOOT'
			)
		),
		(
			(	
			SELECT a.actor_id 
			FROM actor a
			WHERE a.first_name = 'HUBERTUS' AND a.last_name = 'BENGSCH'
			),
			(
			SELECT f.film_id 
			FROM film f
			WHERE UPPER(f.title) = 'DAS BOOT'
			)
		),
		(
			(	
			SELECT a.actor_id 
			FROM actor a
			WHERE a.first_name = 'HENRY' AND a.last_name = 'FONDA'
			),
			(
			SELECT f.film_id 
			FROM film f
			WHERE UPPER(f.title) = '12 ANGRY MEN'
			)
		),
		(
			(	
			SELECT a.actor_id 
			FROM actor a
			WHERE a.first_name = 'MARTIN' AND a.last_name = 'BALSAM'
			),
			(
			SELECT f.film_id 
			FROM film f
			WHERE UPPER(f.title) = '12 ANGRY MEN'
			)
		)
	) AS new_film_actor (actor_id, film_id)
WHERE NOT EXISTS (										-- The WHERE NOT EXISTS clause is corrected.
SELECT 1
FROM public.film_actor fa
WHERE 	fa.actor_id 	= new_film_actor.actor_id AND
		fa.film_id 		= new_film_actor.film_id
	);

-- Task 1 Part 3
-- Add your favorite movies to any store's inventory.

/* 
 * The INSERT statement inserts 3 new records to the inventory table.
 * The statements SELECT the film_id from the film table based on film title, and add a chosen store_id (1).  
 */

INSERT INTO public.inventory (film_id, store_id)
SELECT 	new_inventory.film_id,
		new_inventory.store_id
FROM (VALUES 
		(
			(
			SELECT f.film_id
			FROM public.film f
			WHERE UPPER(f.title) = ('LORD OF THE RINGS') 
			),
			(
			SELECT s.store_id 
			FROM public.store s 
			LIMIT 1
			)
		),
		(
			(
			SELECT f.film_id
			FROM public.film f
			WHERE UPPER(f.title) = ('DAS BOOT') 
			),
			(
			SELECT s.store_id 
			FROM public.store s 
			LIMIT 1
			)
		),
		(
			(
			SELECT f.film_id
			FROM public.film f
			WHERE UPPER(f.title) = ('12 ANGRY MEN') 
			),
			(
			SELECT s.store_id 
			FROM public.store s 
			LIMIT 1
			)
		) 
	) AS new_inventory (film_id, store_id)
WHERE NOT EXISTS (										-- The WHERE NOT EXISTS clause is corrected.
	SELECT 1
	FROM public.inventory i 
	WHERE 	i.film_id 	= new_inventory.film_id AND 
			i.store_id 	= new_inventory.store_id
	);

-- Task 1 Part 4
/* 
 * Alter any existing customer in the database with at least 43 rental and 43 payment records. 
 * Change their personal data to yours (first name, last name, address, etc.). 
 * You can use any existing address from the "address" table. 
 * Please do not perform any updates on the "address" table, as this can impact multiple records with the same address. 
 */

UPDATE public.customer
SET	store_id 	= (
		SELECT s.store_id 
		FROM public.store s 
		LIMIT 1
        ),
	first_name 	= 'NAME',
	last_name 	= 'SURNAME',
	email 		= 'mail.com',
	address_id 	= (
		SELECT a.address_id
		FROM public.address a
		LIMIT 1
		)
WHERE customer_id = (
	SELECT c.customer_id
	FROM public.customer c
	INNER JOIN public.rental r      ON c.customer_id 	= r.customer_id 
    INNER JOIN public.payment p     ON r.rental_id 		= p.rental_id
    GROUP BY c.customer_id
    HAVING 	COUNT(r.rental_id) 	>= 43 AND 
    		COUNT(p.payment_id) >= 43
    LIMIT 1
	)
RETURNING customer_id;

-- Task 1 Part 5
-- Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'

/* 
 * According to the schema, the only tables with records related to the customer are customer, rental, and payment. 
 * Since we keep the customer record, we need to DELETE from rental and payment tables.
 * A SELECT subquery finds my customer_id. 
 * Since rental and payment tables are connected by a foreign key, they can only be DELETED from simultaneously.
 * Using a CTE and calling it from the main DELETE statement results in both tables being DELETED from at the same time. 
 */
WITH cte_delete_rental AS (
	DELETE FROM public.rental r
	WHERE r.customer_id IN (
		SELECT c.customer_id 
		FROM customer c
		WHERE 	UPPER(first_name)	= 'NAME' AND
				UPPER(last_name)	= 'SURNAME'
		)
	RETURNING r.customer_id
	)
DELETE FROM public.payment p
WHERE p.customer_id IN (
	SELECT cte.customer_id
	FROM cte_delete_rental cte
	GROUP BY cte.customer_id
	);

-- Task 1 Part 6
-- Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)

/* This statement creates a new partition of public.payment for timestamps in 2023 */
CREATE TABLE IF NOT EXISTS public.payment_p2023 PARTITION OF public.payment FOR VALUES FROM ('2023-01-01 00:00:00+01') TO ('2023-12-31 22:00:00+01');

/* 
 * In order to rent an inventory item, we need a new record in the rental and payment tables.
 * These tables are joined by foreign keys, therefore entries need to be added in a single transaction.
 * The cte_rent CTE creates the entry in the rental table and returns values too - the autoincremented rental_id, and the subqueried inventory_id, customer_id, staff_id values.
 * Returning the values enforces data consistency and reuses the subquery results, saving compute.
 * Since this is a practice task, the rental_date is a random timestamp between the original HW submission and NOW() and the return_date is NOW().
 * This way the actual payment calculation in the INSERT statement is dynamic.
 * The main INSERT statement calls the CTE and joins the necessary inventory and film tables to complete the payment record.
 * The payment amount is calculated dynamically according to the (fixed get_customer_balance equation). 
 */

WITH cte_rent AS (
	INSERT INTO public.rental (rental_date, return_date, inventory_id, customer_id, staff_id)
	VALUES 	(
				(
				SELECT 	TIMESTAMP '2023-10-31 01:39:54' +
						RANDOM() * (NOW() - TIMESTAMP '2023-10-31 01:39:54')
				),
				(
				SELECT NOW()
				),
				(
				SELECT i.inventory_id										-- Non-deterministic subquery used instead of randomization
				FROM public.inventory i
				WHERE i.film_id = (
					SELECT f.film_id 
					FROM public.film f
					WHERE UPPER(f.title) = 'LORD OF THE RINGS'
					LIMIT 1
					)
				),
				(
				SELECT c.customer_id										-- Non-deterministic subquery used instead of randomization
				FROM public.customer c
				WHERE   UPPER(c.first_name)   = 'TAMAS' AND
        				UPPER(c.last_name)    = 'PETROCZI'
				),
				(
				SELECT s.staff_id 											-- Non-deterministic subquery used instead of randomization
				FROM public.staff s 
				WHERE s.store_id = (
					SELECT i.store_id
					FROM public.inventory i 
					INNER JOIN public.film f ON i.film_id = f.film_id
					WHERE UPPER(f.title) = 'LORD OF THE RINGS'
					LIMIT 1
					) 
				LIMIT 1
				)
			)
	RETURNING 	rental_id,
				rental_date,
				return_date,
				inventory_id,
				customer_id,
				staff_id 
	)
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT	cte.customer_id,
		cte.staff_id,
		cte.rental_id, 
		(
		SELECT (CASE 
			WHEN 	(cte.return_date - cte.rental_date) <= 	(f.rental_duration * '1 day'::INTERVAL) 
				THEN f.rental_rate
			WHEN 	(cte.return_date - cte.rental_date) > 	(f.rental_duration * '1 day'::INTERVAL) AND 
					(cte.return_date - cte.rental_date) <= 	(f.rental_duration * 2 * '1 day'::INTERVAL)
				THEN f.rental_rate + (EXTRACT(EPOCH FROM ((cte.return_date - cte.rental_date) - (f.rental_duration * '1 day'::INTERVAL)))::INT / 86400)
			ELSE f.replacement_cost
			END
			)
		FROM cte_rent cte
		INNER JOIN public.inventory i 	ON cte.inventory_id 	= i.inventory_id 
		INNER JOIN public.film f		ON i.film_id 			= f.film_id 
		),
		NOW()
FROM cte_rent cte
RETURNING 	rental_id,
			payment_id;