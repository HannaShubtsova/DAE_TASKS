-- Task 2. Implement role-based authentication model for dvd_rental database
-- Part 1.
-- Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
-- Grant "rentaluser" SELECT permission for the "customer" table. ?heck to make sure this permission works correctly—write a SQL query to select all customers.
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'rentaluser') THEN
        CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
    ELSE
        RAISE NOTICE 'User % already exists, skipping creation', 'rentaluser';
    END IF;
END $$;
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
GRANT SELECT ON TABLE customer TO rentaluser;
SELECT SESSION_USER, CURRENT_USER; 
-- Let's connect to dvduser DB with rentaluser credentials:
SET SESSION AUTHORIZATION rentaluser; 
SELECT * FROM customer
LIMIT 5;
/*
customer_id|store_id|first_name|last_name|email                              |address_id|activebool|create_date|last_update                  |active|
-----------+--------+----------+---------+-----------------------------------+----------+----------+-----------+-----------------------------+------+
          1|       1|MARY      |SMITH    |MARY.SMITH@sakilacustomer.org      |         5|true      | 2017-02-14|2017-02-15 07:57:20.000 +0100|     1|
          2|       1|PATRICIA  |JOHNSON  |PATRICIA.JOHNSON@sakilacustomer.org|         6|true      | 2017-02-14|2017-02-15 07:57:20.000 +0100|     1|
          3|       1|LINDA     |WILLIAMS |LINDA.WILLIAMS@sakilacustomer.org  |         7|true      | 2017-02-14|2017-02-15 07:57:20.000 +0100|     1|
          4|       2|BARBARA   |JONES    |BARBARA.JONES@sakilacustomer.org   |         8|true      | 2017-02-14|2017-02-15 07:57:20.000 +0100|     1|
          5|       1|ELIZABETH |BROWN    |ELIZABETH.BROWN@sakilacustomer.org |         9|true      | 2017-02-14|2017-02-15 07:57:20.000 +0100|     1| */
-- and the access to other objects if ristricted for this user.



-- Part 2.
-- Create a new user group called "rental" and add "rentaluser" to the group. 
-- Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 

SET SESSION AUTHORIZATION postgres;
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_group WHERE groname = 'rental') THEN
        CREATE GROUP rental WITH USER rentaluser;
    ELSE
        RAISE NOTICE 'Group % already exists, skipping creation', 'rental';
    END IF;
END $$;

--     ALTER GROUP rental ADD USER rentaluser;
GRANT SELECT ON rental TO rental;
GRANT INSERT ON rental TO rental;
GRANT UPDATE ON rental TO rental;
GRANT INSERT ON rental TO rental;
GRANT UPDATE ON rental TO rental;
GRANT INSERT, UPDATE ON rental_rental_id_seq TO rental;
GRANT SELECT ON film, 
				inventory, 
				store, 
				staff, 
				customer, 
				language, 
				store, 
				address, 
				city, 
				country
				TO rental;
SET SESSION AUTHORIZATION rentaluser;



-- Part 3. Insert a new row and update one existing row in the "rental" table under that role. 

-- For inserting a row I chose a customer Ross Grey who wants to rent a movie 'Chamber Italian', English, 1995 from the store at 47 MySakila Drive.
SELECT * FROM rental ORDER BY last_update DESC;
SELECT * FROM customer JOIN store ON store.store_id = customer.store_id WHERE UPPER(customer.first_name||' '||customer.last_name) = 'ROSS GREY';

INSERT INTO rental ( 
					rental_date, 
					inventory_id, 
					customer_id, 
					staff_id
					)		   
SELECT NOW(), ( -- on the basis of film let's choose the list of inventory ids, that are available:
	   				  SELECT inventory.inventory_id
	   				  FROM inventory
	   				  JOIN film ON film.film_id = inventory.film_id
	   				  JOIN "language" ON LANGUAGE.language_id = film.language_id
	   				  JOIN rental ON inventory.inventory_id = rental.inventory_id 
	   				  WHERE UPPER(title) =  'CHAMBER ITALIAN' AND LANGUAGE.name = 'English' AND release_year = 1995
	   				  AND store_id = (SELECT store_id
	   				  				  FROM customer
	   				  				  -- we are interested only in inventories which are available in stores, where our customer rents DVDs
	   				  				  WHERE UPPER(customer.first_name||' '||customer.last_name) = 'ROSS GREY')
	   				  AND (inventory.inventory_id NOT IN (SELECT rental.inventory_id FROM rental) OR return_date IS NOT NULL)
	   				  -- as soon as there can be many DVDs in stock with the same film, we should limit our search with any one invetnory_id
	   				  LIMIT 1
	   				  ),
	   				  (
	   				  SELECT customer_id
	   				  FROM customer
	   				  WHERE UPPER(customer.first_name||' '||customer.last_name) = 'ROSS GREY'
	   				  ),
	   				  (
	   				  SELECT staff_id
	   				  FROM staff
	   				  WHERE UPPER(staff.first_name||' '||staff.last_name) = 'HANNA RAINBOW'
	   				  -- let's ensure that the person works at store where Ross rents DVDs:
	   				  AND staff.store_id = (SELECT store_id
	   				  				  FROM customer
	   				  				  -- we are interested only in inventories which are available in stores, where our customer rents DVDs
	   				  				  WHERE UPPER(customer.first_name||' '||customer.last_name) = 'ROSS GREY')
	   				  )
ON CONFLICT DO NOTHING;
SELECT * FROM rental
JOIN customer ON rental.customer_id = customer.customer_id 
WHERE UPPER(customer.first_name||' '||customer.last_name) = 'ROSS GREY'
ORDER BY rental_date DESC;
	
SELECT * FROM rental ORDER BY last_update DESC;


-- Here I want to choose one client, Marie Turner, who desides to give back DVD with movie American Circus, English, 2000 which she rented at '2017-02-14 13:16:03.000 +0100'.
-- Here I suppose that here can be many records cooresponding Mary renting this movie, but I need just one case.
-- I checked that before Update return date for that movie is null.
UPDATE rental
SET return_date = NOW()
WHERE inventory_id = 
					(					
					SELECT inventory.inventory_id
					FROM rental
					JOIN inventory ON rental.inventory_id = inventory.inventory_id 
					JOIN film ON film.film_id = inventory.film_id
					JOIN "language" ON LANGUAGE.language_id = film.language_id
					JOIN customer ON customer.customer_id = rental.customer_id 
					WHERE  UPPER(title) = UPPER('AMERICAN CIRCUS') AND LANGUAGE.name = 'English' AND release_year = 2000 
					AND return_date IS NULL -- after update was performed once, during rerun the ROW will remain unchanged -- we can give the dvd back just once.
					--our customer:
					AND rental.customer_id = ( 
										SELECT customer_id
										FROM customer
										WHERE UPPER(customer.first_name||' '||customer.last_name) = 'MARIE TURNER'
									   )
					-- disctinct case when she rented the DVD:
					AND rental_date = '2017-02-14 13:16:03.000 +0100'
					)				  
					AND rental_date = '2017-02-14 13:16:03.000 +0100' -- we need ONLY one ROW with distinct rental date, IF we omit this line, 
																	  --there IS a chance that MORE than one ROW will be changed.
					;
				
SELECT * FROM rental ORDER BY last_update DESC;



-- Part 4. -- Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.

SELECT SESSION_USER, CURRENT_USER;
SET SESSION AUTHORIZATION postgres;
REVOKE INSERT ON rental
FROM rental;
SET SESSION AUTHORIZATION rental;


	INSERT INTO rental ( 
					rental_date, 
					inventory_id, 
					customer_id, 
					staff_id
					)		   
	SELECT NOW(), ( -- on the basis of film let's choose the list of inventory ids, that are available:
	   				  SELECT inventory.inventory_id
	   				  FROM inventory
	   				  JOIN film ON film.film_id = inventory.film_id
	   				  JOIN "language" ON LANGUAGE.language_id = film.language_id
	   				  JOIN rental ON inventory.inventory_id = rental.inventory_id 
	   				  WHERE UPPER(title) =  'ANNIE IDENTITY' AND LANGUAGE.name = 'English' AND release_year = 2008
	   				  AND store_id = (SELECT store_id
	   				  				  FROM customer
	   				  				  -- we are interested only in inventories which are available in stores, where our customer rents DVDs
	   				  				  WHERE UPPER(customer.first_name||' '||customer.last_name) = 'ROSS GREY')
	   				  AND (inventory.inventory_id NOT IN (SELECT rental.inventory_id FROM rental) OR return_date IS NOT NULL)
	   				  -- as soon as there can be many DVDs in stock with the same film, we should limit our search with any one invetnory_id
	   				  LIMIT 1
	   				  ),
	   				  (
	   				  SELECT customer_id
	   				  FROM customer
	   				  WHERE UPPER(customer.first_name||' '||customer.last_name) = 'ROSS GREY'
	   				  ),
	   				  (
	   				  SELECT staff_id
	   				  FROM staff
	   				  WHERE UPPER(staff.first_name||' '||staff.last_name) = 'HANNA RAINBOW'
	   				  -- let's ensure that the person works at store where Ross rents DVDs:
	   				  AND staff.store_id = (SELECT store_id
	   				  				  FROM customer
	   				  				  -- we are interested only in inventories which are available in stores, where our customer rents DVDs
	   				  				  WHERE UPPER(customer.first_name||' '||customer.last_name) = 'ROSS GREY')
	   				  )
	ON CONFLICT DO NOTHING;
	
SELECT * FROM film;
-- permission denied Error



-- Part 5. -- Create a personalized role for any customer already existing in the dvd_rental database. 
-- The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
-- The customer's payment and rental history must not be empty. 

SET SESSION AUTHORIZATION postgres;


-- let's write a function that creates for any person existing in the database and having nonempty payment and rental history:
CREATE OR REPLACE FUNCTION create_customer_role(client_first_name TEXT, client_last_name TEXT)
RETURNS void
LANGUAGE plpgsql
AS $$ 
DECLARE
    role_name TEXT;
BEGIN
    -- Check if there's any rental and payment history for the customer:
    IF EXISTS (
        		SELECT 
        		FROM customer
        		JOIN rental ON customer.customer_id = rental.customer_id
        		JOIN payment ON payment.rental_id = rental.rental_id    		
        		WHERE customer.first_name = client_first_name AND customer.last_name = client_last_name
    			)
    -- if TRUE then:
    THEN
    	    -- Construct role_name variable based on client first and last name
    	 role_name := 'client_' || LOWER(client_first_name || '_' || client_last_name);
    	        -- Check if the role already exists:
         IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = role_name) 
         THEN
              EXECUTE format('CREATE ROLE %I', role_name);
              RAISE NOTICE 'Role % created successfully:', role_name;
          ELSE RAISE NOTICE 'Role % already exists, skipping creation.', role_name;
          END IF;
    	 ELSE
        RAISE NOTICE 'Client % % does not exist in database or has no rentals or payments', client_first_name, client_last_name;
    END IF;
END $$;

-- let' create role:
SELECT create_customer_role('CHRISTINE'::TEXT, 'ROBERTS'::TEXT);

SELECT *
FROM pg_catalog.pg_roles ;

