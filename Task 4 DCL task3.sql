-- Task 3. Implement row-level security
-- Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
-- Write a query to make sure this user sees only their own data.

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;
-- Create policies
-- Selected user can access only their own records
CREATE OR REPLACE FUNCTION create_customer_policy(role_name TEXT)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    client_id INT;
BEGIN
    SELECT customer_id
    INTO client_id
    FROM customer
    WHERE UPPER('CLIENT_'||first_name||'_'||last_name) = UPPER(role_name);
    -- Check if the role we want to create a policy for exists
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = role_name) 
    THEN
        -- Check if the policy already exists
        IF NOT EXISTS (
            			SELECT 1
            			FROM pg_catalog.pg_policies
            			WHERE policyname = 'user_mod'
        				) 
        THEN EXECUTE format('CREATE POLICY user_mod ON rental FOR SELECT TO %I USING (customer_id = %s )', role_name, client_id); -- CREATE POLICY ON rental
             EXECUTE format('CREATE POLICY user_mod ON payment FOR SELECT TO %I USING (customer_id = %s)', role_name, client_id); -- CREATE POLICY ON payment 
             RAISE NOTICE 'Policy user_mod created successfully for role % :', role_name;
        ELSE RAISE NOTICE 'Policy user_mod already exists for role %, skipping policy creation :', role_name;
        END IF;
    ELSE RAISE NOTICE 'Role name % doesn''t exist', role_name;
    END IF;
END;
$$;

SELECT create_customer_policy('client_christine_roberts');
SELECT * FROM pg_catalog.pg_policies;
SET SESSION AUTHORIZATION client_christine_roberts;

SELECT *
FROM rental
JOIN customer ON customer.customer_id = rental.customer_id
WHERE UPPER('CLIENT_'||first_name||'_'||last_name) = UPPER('client_christine_roberts');
-- and for the other rows an access is denied
SET SESSION AUTHORIZATION postgres;
