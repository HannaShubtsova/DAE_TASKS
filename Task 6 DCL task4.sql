Task 4. Prepare answers to the following questions
 - How can one restrict access to certain columns of a database table?
The simplest way to provide certain user an access to certain column of the table instead of providing access to the whole table
is to create a view consisting on that very column, providing the user and access to the view and restriction access to other objects.

The other way is to limit an access by granting access only to certain column of the table:
GRANT SELECT (col1_name, col2_name) ON table_name to user_name;

- What is the difference between user identification and user authentication?

Identification  is user account name, ID etc. - a parameter through which the user is identified inside the system to govern his accesses and privileges.
Authentication is the way the user proofs his identity, for example, by providing the corresponding password.
In general there are many different types of authentication such as multi-factor , biometric, certificate-base authentication.


- What are the recommended authentication protocols for PostgreSQL?
In PostgreSQL by default for users password authentication is used, also certificate-based and external authentication via LDAP of Kerberos are used.

- What is proxy authentication in PostgreSQL and what is it for? Why does it make the previously discussed role-based access control easier to implement?

Proxy authentication is a mechanism where a proxy server or intermediary entity, acting as an intermediary between a client and a server, performs the authentication on behalf of the client.
Instead of the client directly authenticating with the end server, the proxy server handles the authentication process.
Proxy authentication in PostgreSQL typically refers to a method where an intermediary layer or service authenticates users before establishing connections to the database. This intermediary layer acts as a proxy between the client application and the database server, handling the authentication process on behalf of the client.

Role-based access control in PostgreSQL involves granting specific permissions and privileges to database roles or users.
Proxy authentication can ease the implementation of Role-based access control by providing a centralized point for user authentication and access control,
allowing for more granular control over database access based on user roles or attributes.