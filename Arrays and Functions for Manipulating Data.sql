-- Arrays
	/* Create an array containing customers' first name, last name, and email for each customer ID, and 
       then return customer ID, last name, and an array containing the last name and email */
	SELECT
		customer_id,
		customer_info[2],
		ARRAY[customer_info[2], customer_info[3]]
	FROM (SELECT
		       customer_id,
		       ARRAY[first_name, last_name, email] AS customer_info
	      FROM customer
	      ORDER BY customer_id);
	
	-- Return an array containing all rental IDs aggregated for each customer_id
	SELECT
		customer_id,
		ARRAY_AGG(rental_id)
	FROM rental
	GROUP BY customer_id
	ORDER BY COUNT(rental_id) DESC;

	/* Create a 2-dimensional array containing customer's rental details (film title and payment amount as text), and 
       then return the customer ID and payment amount of the first rental in the array for each customer */
	SELECT
		customer_id,
		rental_details[1][2]
	FROM (SELECT 
	          r.customer_id,
	          ARRAY_AGG(ARRAY[f.title, p.amount::TEXT]) AS rental_details
	     FROM rental r
	     INNER JOIN inventory i ON r.inventory_id = i.inventory_id
	     INNER JOIN film f ON i.film_id = f.film_id
	     INNER JOIN payment p ON r.rental_id = p.rental_id
	     GROUP BY r.customer_id
	     ORDER BY r.customer_id);

-- DATE/TIME Functions and Operators
	-- Return average rental duration for each customer ID using arithmetic operators
	SELECT
		customer_id,
		AVG(return_date - rental_date) AS avg_rental_duration
	FROM rental
	GROUP BY customer_id
	ORDER BY avg_rental_duration DESC;
	
	-- Return average rental duration for each customer ID using the AGE function
	SELECT
		customer_id,
		AVG(AGE(return_date, rental_date)) AS rental_duration
	FROM rental
	GROUP BY customer_id
	ORDER BY rental_duration DESC;

	/* Return the customer IDs, their expected return date adding overall average rental duration using the INTERVAL operator, 
       and the expected return date adding each customer average rental duration using a correlated subquery */
	SELECT
		customer_id,
		rental_date + INTERVAL '4 days' AS expected_return_overall_avg,
		rental_date + (SELECT AVG(AGE(return_date, rental_date)) AS rental_duration
	                   FROM rental r2
                       WHERE r1.customer_id = r2.customer_id
	                   GROUP BY customer_id
	                   ORDER BY rental_duration DESC) AS expected_return_customer_avg
	FROM rental r1;

	-- Return average rental duration for each customer as a text string using the CAST function
	SELECT
	    customer_id,
	    CAST(AVG(AGE(return_date, rental_date)) AS TEXT) AS rental_duration_text
	FROM rental
	GROUP BY customer_id
	ORDER BY rental_duration_text DESC;

	-- Return rental count and sales per quarter using the EXTRACT function
	SELECT
	    EXTRACT(quarter FROM r.rental_date) AS quarter,
	    COUNT(r.rental_id) AS rental_count,
	    SUM(p.amount) AS sales
	FROM rental r
	INNER JOIN payment p USING (rental_id)
	WHERE EXTRACT(year FROM rental_date) = 2005
	GROUP BY quarter
	ORDER BY quarter;

	-- (The same result as in the previous query but using the DATE_PART function)
	SELECT
	    DATE_PART('quarter', rental_date) AS quarter,
	    COUNT(r.rental_id) AS rental_count,
	    SUM(amount) AS sales
	FROM rental r
	INNER JOIN payment p USING (rental_id)
	WHERE EXTRACT(year FROM rental_date) = 2005
	GROUP BY quarter
	ORDER BY quarter;

	-- (The same result as in the previous query but using the DATE_TRUNC function)
	SELECT
	    DATE_TRUNC('quarter', rental_date) AS quarter,
	    COUNT(rental_id) AS rental_count,
	    SUM(amount) AS sales
	FROM rental r
	INNER JOIN payment p USING (rental_id)
	WHERE EXTRACT(year FROM rental_date) = 2005
	GROUP BY quarter
	ORDER BY quarter;

-- Parsing and manipulating text
	-- Return 10 most active customers' first names, last names, and emails as customer info using the concentation operator ||
	SELECT
	     c.first_name || ' ' || c.last_name || ' ' ||  email  AS customer_info,
	     COUNT(rental_id) AS rental_count
	FROM customer c
	INNER JOIN rental r USING(customer_id)
	GROUP BY customer_id
	ORDER BY rental_count DESC
	LIMIT 10;

	-- (The same result as in the previous query but using the CONCAT fucntion)
	SELECT
	    CONCAT(c.first_name, ' ', c.last_name, ' ', c.email) AS customer_info,
	    COUNT(r.rental_id) AS rental_count
	FROM customer c
	INNER JOIN rental r USING(customer_id)
	GROUP BY customer_id
	ORDER BY rental_count DESC
	LIMIT 10;

	/* Return the 10 most active customers' first names and last names as customer info,
       and make customer names who rented from store 1 in uppercase and from store 2 in lowercase 
       using the UPPER and LOWER functions */
	SELECT
	    CASE 
	        WHEN c.store_id = 1 THEN UPPER(c.first_name || ' ' || c.last_name)
	        WHEN c.store_id = 2 THEN LOWER(c.first_name || ' ' || c.last_name)
	    END AS customer_info,
	    COUNT(r.rental_id) AS rental_count
	FROM customer c
	INNER JOIN rental r USING(customer_id)
	GROUP BY customer_id
	ORDER BY rental_count DESC
	LIMIT 10;

	/* Return the anonymized names of the customers using the REPLACE function, 
       replacing the first name with the word 'Customer' and concatenating it with the last name and customer id */
	SELECT
	    REPLACE(first_name, first_name, 'Customer') || ' ' || last_name || ', ID:' || customer_id AS anonymized_name
	FROM customer
	ORDER BY last_name;

	-- Return unique lengths of rental IDs and their counts using LENGTH function
	SELECT
		rental_id_length,
		COUNT(rental_id_length) AS rental_id_length_count
	FROM (SELECT 
		       rental_id,
		       LENGTH(CAST(rental_id AS TEXT)) AS rental_id_length
	      FROM rental)
	GROUP BY rental_id_length
	ORDER BY rental_id_length_count;

	-- Return the position of the @ in each customer email using STRPOS function
	SELECT
		CONCAT(first_name, ' ', last_name) AS full_name,
		STRPOS(email, '@') AS at_sign_position
	FROM customer;

	-- Return characters from the left of the @ in each customer email using LEFT function
	SELECT
		CONCAT(first_name, ' ', last_name) AS full_name,
		LEFT(email, (STRPOS(email, '@') - 1)) AS email_before_at_sign
	FROM customer;

	-- Return characters from the right of the @ in each customer email using RIGHT function
	SELECT
		CONCAT(first_name, ' ', last_name) AS full_name,
		RIGHT(email, LENGTH(email) - STRPOS(email, '@')) AS email_after_at_sign
	FROM customer;

	-- (The same result as in the previous query but using the SUBSTRING fucntion)
	SELECT
		CONCAT(first_name, ' ', last_name) AS full_name,
		SUBSTRING(email FROM POSITION('@' IN email) + 1 FOR LENGTH(email)) AS email_after_at_sign
	FROM customer;

	/* Return full-trimmed first name, left-side trimmed first name, and right-side trimmed first name 
		using TRIM, LTRIM, and RTRIM functions */
	SELECT
		TRIM(first_name) AS full_trimmed_first_name,
		LTRIM(first_name) AS left_trimmed_first_name,
		RTRIM(first_name) AS right_trimmed_first_name
	FROM customer;

	-- Return anonymized emails (part before @ padded with *) for each customer using the LPAD function
	SELECT
	    CONCAT(first_name, ' ', last_name) AS full_name,
	    CONCAT(LPAD('', STRPOS(email, '@') - 1, '*'), SUBSTRING(email, STRPOS(email, '@'))) AS anonymized_email
	FROM customer;

	-- Return anonymized emails (part after @ padded with *) for each customer using the RPAD function
	SELECT
	    CONCAT(first_name, ' ', last_name) AS full_name,
	    CONCAT(SUBSTRING(email, 1, STRPOS(email, '@')), RPAD('', LENGTH(email) - STRPOS(email, '@'), '*')) AS anonymized_email
	FROM customer;
	