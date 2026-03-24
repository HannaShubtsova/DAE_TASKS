Task 1. Figure out what security precautions are already used in your 'dvd_rental' database.  Prepare description
While talking about security precautions in PostgreSQL we should investigate privileges and roles existing in database.
A privilege is a specific database operation which user can perform on a database objects.
Role is a named set of privileges.
First of all let's check how many schemas is there in our dvdrental database:
dvdrental=#  \dn
      List of schemas
  Name  |       Owner
--------+-------------------
 public | pg_database_owner
(1 row)

and how many users exist:
dvdrental=#  \du
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}

So, as we can see, there's one default schema with default user.

If we perform the following selection:
SELECT
    table_schema,
    table_name,
    grantee,
    array_agg( privilege_type) AS privilege_type
FROM
    information_schema.table_privileges
WHERE
    table_schema = 'public'
    GROUP BY table_name, table_schema , grantee;

We can see that all public schema tables privileges have the same (default) grantee - postgres:
table_schema|table_name                   |grantee |privilege_type                                           |
------------+-----------------------------+--------+---------------------------------------------------------+
public      |actor                        |postgres|{TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT,INSERT}|
public      |actor_info                   |postgres|{INSERT,SELECT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER}|
public      |address                      |postgres|{INSERT,TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT}|
public      |category                     |postgres|{TRIGGER,REFERENCES,INSERT,TRUNCATE,DELETE,UPDATE,SELECT}|
public      |city                         |postgres|{UPDATE,INSERT,SELECT,DELETE,TRUNCATE,REFERENCES,TRIGGER}|
public      |country                      |postgres|{INSERT,TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT}|
public      |customer                     |postgres|{TRIGGER,INSERT,SELECT,UPDATE,DELETE,TRUNCATE,REFERENCES}|
public      |customer_list                |postgres|{INSERT,SELECT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER}|
public      |film                         |postgres|{SELECT,TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,INSERT}|
public      |film_actor                   |postgres|{INSERT,SELECT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER}|
public      |film_category                |postgres|{DELETE,INSERT,SELECT,UPDATE,TRUNCATE,REFERENCES,TRIGGER}|
public      |film_list                    |postgres|{INSERT,TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT}|
public      |inventory                    |postgres|{DELETE,INSERT,SELECT,UPDATE,TRUNCATE,REFERENCES,TRIGGER}|
public      |language                     |postgres|{INSERT,SELECT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER}|
public      |memory_report                |postgres|{REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT,INSERT,TRIGGER}|
public      |my_fav_film                  |postgres|{TRIGGER,UPDATE,DELETE,INSERT,TRUNCATE,REFERENCES,SELECT}|
public      |nicer_but_slower_film_list   |postgres|{TRIGGER,SELECT,UPDATE,DELETE,TRUNCATE,REFERENCES,INSERT}|
public      |payment                      |postgres|{INSERT,TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT}|
public      |payment_p2017_01             |postgres|{TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT,INSERT}|
public      |payment_p2017_02             |postgres|{TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT,INSERT}|
public      |payment_p2017_03             |postgres|{TRIGGER,INSERT,SELECT,UPDATE,DELETE,TRUNCATE,REFERENCES}|
public      |payment_p2017_04             |postgres|{SELECT,INSERT,TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE}|
public      |payment_p2017_05             |postgres|{SELECT,REFERENCES,TRIGGER,INSERT,TRUNCATE,DELETE,UPDATE}|
public      |payment_p2017_06             |postgres|{TRUNCATE,INSERT,TRIGGER,REFERENCES,DELETE,UPDATE,SELECT}|
public      |rental                       |postgres|{TRIGGER,INSERT,SELECT,UPDATE,DELETE,TRUNCATE,REFERENCES}|
public      |sales_by_film_category       |postgres|{INSERT,TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT}|
public      |sales_by_store               |postgres|{DELETE,TRIGGER,REFERENCES,TRUNCATE,UPDATE,SELECT,INSERT}|
public      |sales_revenue_by_category_qtr|postgres|{INSERT,TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT}|
public      |staff                        |postgres|{INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER,SELECT}|
public      |staff_list                   |postgres|{TRIGGER,INSERT,SELECT,UPDATE,DELETE,TRUNCATE,REFERENCES}|
public      |store                        |postgres|{TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT,INSERT}|
public      |table_to_delete              |postgres|{TRIGGER,REFERENCES,TRUNCATE,DELETE,UPDATE,SELECT,INSERT}|



Using \dp command we can achieve the list of all tables and privileges. As we can see, privileges columns are empty.
Similar table with wider list of database objects we can retrieve using \z command.
dvdrental=# \dp
                                               Access privileges
 Schema |             Name              |       Type        | Access privileges | Column privileges | Policies
--------+-------------------------------+-------------------+-------------------+-------------------+----------
 public | actor                         | table             |                   |                   |
 public | actor_actor_id_seq            | sequence          |                   |                   |
 public | actor_info                    | view              |                   |                   |
 public | address                       | table             |                   |                   |
 public | address_address_id_seq        | sequence          |                   |                   |
 public | category                      | table             |                   |                   |
 public | category_category_id_seq      | sequence          |                   |                   |
 public | city                          | table             |                   |                   |
 public | city_city_id_seq              | sequence          |                   |                   |
 public | country                       | table             |                   |                   |
 public | country_country_id_seq        | sequence          |                   |                   |
 public | customer                      | table             |                   |                   |
 public | customer_customer_id_seq      | sequence          |                   |                   |
 public | customer_customer_id_seq1     | sequence          |                   |                   |
 public | customer_list                 | view              |                   |                   |
 public | film                          | table             |                   |                   |
 public | film_actor                    | table             |                   |                   |
 public | film_category                 | table             |                   |                   |
:

let's retrieve the list ad characteristiics of the existing roles:
SELECT rolname AS "Role Name",
       rolsuper AS "Is Superuser?",
       rolinherit AS "Can Inherit?",
       rolcreaterole AS "Can Create Role?",
       rolcreatedb AS "Can Create DB?",
       rolcanlogin AS "Can Login?",
       rolreplication AS "Is Replication Role?",
       rolbypassrls AS "Bypasses RLS?",
       rolconnlimit AS "Connection Limit",
       rolvaliduntil AS "Valid Until",
       rolconfig AS "Role Configuration"
FROM pg_roles;
Role Name                  |Is Superuser?|Can Inherit?|Can Create Role?|Can Create DB?|Can Login?|Is Replication Role?|Bypasses RLS?|Connection Limit|Valid Until|Role Configuration|
---------------------------+-------------+------------+----------------+--------------+----------+--------------------+-------------+----------------+-----------+------------------+
pg_database_owner          |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_read_all_data           |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_write_all_data          |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_monitor                 |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_read_all_settings       |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_read_all_stats          |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_stat_scan_tables        |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_read_server_files       |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_write_server_files      |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_execute_server_program  |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_signal_backend          |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_checkpoint              |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_use_reserved_connections|false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
pg_create_subscription     |false        |true        |false           |false         |false     |false               |false        |              -1|           |NULL              |
postgres                   |true         |true        |true            |true          |true      |true                |true         |              -1|           |NULL              |

And finally we can check, which row Policies exist in the database:
dvdrental=# \d pg_policy
                 Table "pg_catalog.pg_policy"
    Column     |     Type     | Collation | Nullable | Default
---------------+--------------+-----------+----------+---------
 oid           | oid          |           | not null |
 polname       | name         |           | not null |
 polrelid      | oid          |           | not null |
 polcmd        | "char"       |           | not null |
 polpermissive | boolean      |           | not null |
 polroles      | oid[]        |           | not null |
 polqual       | pg_node_tree | C         |          |
 polwithcheck  | pg_node_tree | C         |          |
