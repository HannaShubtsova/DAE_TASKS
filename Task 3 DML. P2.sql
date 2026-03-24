-- ______________________________________ TASK DESCRIPTION ________________________________________________
-- 1. Create table ‘table_to_delete’ and fill it with the query
-- 2. Lookup how much space this table consumes with the  query
-- 3. Issue the DELETE operation on ‘table_to_delete’
-- 		a) Note how much time it takes to perform this DELETE statement
-- 		b) Lookup how much space this table consumes after previous DELETE
-- 		c) Perform VACUUM
-- 		d) Check space consumption of the table once again and make conclusions
-- 		e) Recreate ‘table_to_delete’ table;
-- 4. Issue the TRUNCATE operation:
-- 		a) Note how much time it takes to perform this TRUNCATE statement.
-- 		b) Compare with previous results and make conclusion.
-- 		c) Check space consumption of the table once again and make conclusions;
-- 5. Hand over your investigation's results to your trainer. The results must include:
-- 		a) Space consumption of ‘table_to_delete’ table before and after each operation
-- 		b) Duration of each operation (DELETE, TRUNCATE)

-- ______________________________________ OPERATIONS AND NOTES ________________________________________________
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x; 


SELECT
 	*,
	pg_size_pretty(total_bytes) AS total,
    pg_size_pretty(index_bytes) AS INDEX,
    pg_size_pretty(toast_bytes) AS toast,
    pg_size_pretty(table_bytes) AS TABLE
FROM (	
		SELECT
				*,
				total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
		FROM (
				SELECT 
					c.oid,
					nspname AS table_schema,
		  			relname AS TABLE_NAME,
		      		c.reltuples AS row_estimate,
		      		pg_total_relation_size(c.oid) AS total_bytes, 
		      		pg_indexes_size(c.oid) AS index_bytes,
		      		pg_total_relation_size(reltoastrelid) AS toast_bytes 
		      	FROM pg_class c LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
		      	WHERE relkind = 'r'
              ) a
    ) a
WHERE table_name LIKE '%table_to_delete%';
/* NOTES AFTER CREATION: 	ROW-ESTIMATE: -1.0,
							TOTAL-BYTES: 602456064,
							INDEX-BYTES: 0,
							TOAST-BYTES: 8192, 
							TABLE-BYTES: 602447872, 
							TOTAL: 575 MB, 
							INDEX: 0 bytes, 
							TOAST: 8192 bytes, 
							TABLE: 575 MB */

DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;
/* NOTES AFTER DELETING:	ROW-ESTIMATE: 9999700,
							TOTAL-BYTES: 602611712,
							INDEX-BYTES: 0, 
							TOAST-BYTES: 8192, 
							TABLE-BYTES: 602603520, 
							TOTAL: 575 MB, 
							INDEX: 0 bytes, 
							TOAST: 8192 bytes, 
							TABLE: 575 MB */
VACUUM FULL VERBOSE table_to_delete;
/* NOTES AFTER VACUUM AFTER DELETING:	ROW-ESTIMATE: 6666667,
										TOTAL-BYTES: 401645568,
										INDEX-BYTES: 0, 
										TOAST-BYTES: 8192, 
										TABLE-BYTES: 401637376, 
										TOTAL: 383 MB, 
										INDEX: 0 bytes, 
										TOAST: 8192 bytes, 
										TABLE: 383 MB */

DROP TABLE table_to_delete;

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x; 


TRUNCATE table_to_delete;
/* NOTES AFTER TRANCATE: 	ROW-ESTIMATE: 0,
							TOTAL-BYTES: 8192, 
							INDEX-BYTES: 0, 
							TOAST-BYTES: 8192, 
							TABLE-BYTES: 0, 
							TOTAL: 8192 bytes, 
							INDEX: 0 bytes, 
							TOAST: 8192 bytes, 
							TABLE: 8192 bytes */


-- ______________________________________________ RESPONSES ____________________________________________________

/*							     
___DELETE OPERATION (duration 10 seconds): 
TABLE-BYTES before: 602447872 
TABLE-BYTES after:	602603520 (increased by 155 kb)

	CONCLUSION: the log file about transaciion appeared, and in general DELETE operation doesn't free up space and
				doesn't physically remove deleted tuples from the table
 

___VACUUM OPERATION: 
TABLE-BYTES before:	602603520 
TABLE-BYTES after:	401637376 (decreased by 200 mb)
ROW-ESTIMATE before: 9999700
 ROW-ESTIMATE after: 6666667 (decreased by 3 333 033)
  
	CONCLUSION: VACCUM allows to reclaim storage occupied by already deleted tuples. And in addition FULL VACUUM
 				rewrites the content of the table into a new file, it allows to return old space to the OS. 
 
  
___TRUNCATE OPERATION (duration 0 seconds): 
TABLE-BYTES before:	602447872 (new recreated table)
TABLE-BYTES after:	0 (reclaimed at all)
ROW-ESTIMATE before: 9999896
ROW-ESTIMATE after:	0 (cleaned all)
 
	CONCLUSION: TRUNCATE not only deletes the data from the table, but also physically romoves deleted tuples
				so that they don't take up space. It's something like a mix of DELETE + VACUUM, but much faster (immediately)*/
