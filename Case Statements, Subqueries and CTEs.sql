-- CASE
	-- Return rental count and activity level (based on logical conditions) for each customer
	SELECT
    	c.first_name || ' ' || c.last_name AS full_name,
    	COUNT(r.rental_id) AS rental_count,
    	CASE WHEN COUNT(r.rental_id) > 29 THEN 'High Activity'
        	 WHEN COUNT(r.rental_id) BETWEEN 15 AND 29 THEN 'Medium Activity'
        	 ELSE 'Low Activity'
    		 END AS activity_level
	FROM customer c
	INNER JOIN rental r USING(customer_id)
	GROUP BY c.customer_id
	ORDER BY rental_count DESC;

-- CASE with multiple logical conditions in WHEN clause
	-- Return rental count and customer tier (based on multiple logical conditions) for each customer
	SELECT
	    c.first_name || ' ' || c.last_name AS full_name,
	    COUNT(r.rental_id) AS rental_count,
	    SUM(p.amount) AS total_spent,
	    CASE WHEN COUNT(r.rental_id) > 29 AND SUM(p.amount) > 120 THEN 'Premium'
	         WHEN COUNT(r.rental_id) BETWEEN 15 AND 29 AND SUM(p.amount) BETWEEN 60 AND 120 THEN 'Regular'
	         WHEN COUNT(r.rental_id) < 15 AND SUM(p.amount) < 60 THEN 'Occasional'
	         ELSE 'Uncategorized'
	         END AS customer_tier
	FROM customer c
	INNER JOIN rental r USING(customer_id)
	INNER JOIN payment p USING(rental_id)
	GROUP BY c.customer_id
	ORDER BY rental_count DESC;

-- Subqueries inside SELECT
	-- Return all rented film categories and their rental count
	SELECT
		c.name,
		(SELECT COUNT(*)
		FROM rental r
		INNER JOIN inventory i USING(inventory_id)
		INNER JOIN film f USING(film_id)
		INNER JOIN film_category fc USING(film_id)
		WHERE fc.category_id = c.category_id) AS rental_count
	FROM category c
	ORDER BY rental_count DESC;
	
	-- (The same result as in the previous query but with join) 
	SELECT
		c.name,
		COUNT(r.rental_id) AS rental_count
	FROM rental r
	INNER JOIN inventory i USING(inventory_id)
	INNER JOIN film f USING(film_id)
	INNER JOIN film_category fc USING(film_id)
	INNER JOIN category c USING(category_id)
	GROUP BY c.name
	ORDER BY rental_count DESC;

	-- Return all rented film categories and their rental count along with the total count of rentals 
	SELECT
		c.name,
		COUNT(r.rental_id) AS rental_count,
		(SELECT COUNT(*)
		 FROM rental) AS total_rental_count 
	FROM rental r
	INNER JOIN inventory i USING(inventory_id)
	INNER JOIN film f USING(film_id)
	INNER JOIN film_category fc USING(film_id)
	INNER JOIN category c USING(category_id)
	GROUP BY c.name
	ORDER BY rental_count DESC;

	-- Return the difference of category average rental duration from the overall average rental duration in descending order
	SELECT
		c.name,
		ROUND(AVG(f.rental_duration) - (SELECT AVG(rental_duration)
		                                FROM film), 2) AS diff 
	FROM film f
	INNER JOIN film_category fc USING(film_id)
	INNER JOIN category c USING(category_id)
	GROUP BY c.name
	ORDER BY diff DESC;

-- Subqueries inside FROM
	-- Return films with more than 30 rentals and their inventory count in ascending order
	SELECT
		rentals.film_id,
    	rentals.title,
		COUNT(inventory_id) AS inventory_count
	FROM (SELECT
	           f.film_id,
               f.title,
               COUNT(r.rental_id) AS rental_count
		  FROM film f
		  INNER JOIN inventory i USING(film_id)
		  INNER JOIN rental r USING(inventory_id)
		  GROUP BY f.film_id, f.title
    	  HAVING COUNT(r.rental_id) > 30) AS rentals
	INNER JOIN inventory i USING(film_id)
	GROUP BY rentals.film_id, rentals.title
	ORDER BY inventory_count;

	-- Return the average sales per film
	SELECT ROUND(AVG(sales), 2)
	FROM (SELECT
		       f.title,
			   SUM(amount) AS sales
		  FROM film f
		  INNER JOIN inventory i USING(film_id)
		  INNER JOIN rental r USING(inventory_id)
		  INNER JOIN payment p USING(rental_id)
		  GROUP BY f.title);

-- Subqueries inside WHERE
	-- Return payments with the amount higher than the average across all rentals
	SELECT *
	FROM payment
	WHERE amount > (SELECT AVG(amount)
					FROM payment);

	-- Return rentals with the payment amount higher than 10
	SELECT * 
	FROM rental r
	WHERE rental_id IN (SELECT rental_id
    	                FROM payment p
		                WHERE amount > 10);
			
-- Nested suqueries
	-- Return rented film titles that have more rentals than the average across all films
	SELECT 
		f.title,
		COUNT(r.rental_id) AS rental_count
	FROM film f
	INNER JOIN inventory i USING(film_id)
	INNER JOIN rental r USING(inventory_id)
	GROUP BY f.title
	HAVING COUNT(r.rental_id) > (SELECT AVG(rental_count)
                                 FROM (SELECT COUNT(rental_id) AS rental_count
		                               FROM film f
		                               INNER JOIN inventory i USING(film_id)
		                               INNER JOIN rental r USING(inventory_id)
		                               GROUP BY f.title));

-- Correlated subqueries 
	-- Return all rented film categories and customer count who rented films from this category
	SELECT
		c.name,
		(SELECT COUNT(DISTINCT customer_id)
		 FROM rental r
		 INNER JOIN inventory i USING(inventory_id)
		 INNER JOIN film f USING(film_id)
		 INNER JOIN film_category fc USING(film_id)
		 WHERE fc.category_id = c.category_id) AS customer_count
	FROM category c
	ORDER BY customer_count DESC;

	-- Return all rentals where the payment amount is greater than the average payment amount for the same customer
	SELECT
	    rental_id,
	    payment_date,
	    customer_id,
	    amount
	FROM payment p1
	WHERE amount > (SELECT AVG(p2.amount)
    				FROM payment p2
    				WHERE p2.customer_id = p1.customer_id);

-- Subqueries everywhere
	 /* Return "Action" film titles, their total sales, average payment amount per rental, 
        and the average sales across all films, including only those films with a rental count greater 
        than the average rental count across all films. Order by total sales in descending order */ 
		
		SELECT 
		    f2.title,
			
			-- Sales for each film
			(SELECT SUM(p.amount) 
		     FROM payment p
		     INNER JOIN rental r USING(rental_id)
		     INNER JOIN inventory i USING(inventory_id)
		     WHERE i.film_id = f2.film_id) AS sales,
			
			-- Average payment amount for each film
			(SELECT ROUND(AVG(p.amount), 2) 
		     FROM payment p
		     INNER JOIN rental r USING(rental_id)
		     INNER JOIN inventory i USING(inventory_id)
		     WHERE i.film_id = f2.film_id) AS avg_payment_amount,
			
			-- Average sales per film across all films
		    (SELECT ROUND(AVG(sales), 2)
			 FROM (SELECT SUM(amount) AS sales
				   FROM inventory i
				   INNER JOIN rental r USING(inventory_id)
				   INNER JOIN payment p USING(rental_id)
				   GROUP BY i.film_id)) AS avg_sales_across_all_films
		FROM 
		    -- All "Action" films and their rental count
		    (SELECT
				f.film_id,
		        f.title,
		        COUNT(r.rental_id) AS rental_count
		     FROM film f
			 INNER JOIN film_category fc USING(film_id)
		     INNER JOIN category c USING(category_id)
		     INNER JOIN inventory i USING(film_id)
		     INNER JOIN rental r USING(inventory_id)
		     WHERE c.name = 'Action'
		     GROUP BY f.film_id, f.title) AS action_films
		
		INNER JOIN film f2 USING(title)
		
		WHERE 
		    -- Filter for films rented more than the average rental count across all films
		    action_films.rental_count > 
		    (SELECT AVG(rental_count) 
		     FROM (SELECT COUNT(r.rental_id) AS rental_count 
		           FROM rental r 
		           INNER JOIN inventory i USING(inventory_id)
		           GROUP BY i.film_id) AS rental_counts)
		
		ORDER BY sales DESC;

-- Common Table Expressions
	-- (The same result as in the previous query with subqueries everywhere but using CTEs)
	
	-- CTE to calculate total sales and average payment amount for each film
	WITH sales_and_avg_payment_amount AS (
	    SELECT
	        i.film_id,
	        SUM(p.amount) AS sales,
	        ROUND(AVG(p.amount), 2) AS avg_payment_amount
	    FROM payment p
	    INNER JOIN rental r USING(rental_id)
	    INNER JOIN inventory i USING(inventory_id)
	    GROUP BY i.film_id
	),
	-- CTE to calculate the average sales across all films
	avg_sales_across_all_films AS (
	    SELECT ROUND(AVG(sales), 2) AS avg_sales
	    FROM (SELECT SUM(p.amount) AS sales
	          FROM payment p
	          INNER JOIN rental r USING(rental_id)
	          INNER JOIN inventory i USING(inventory_id)
	          GROUP BY i.film_id) AS film_sales
	),
	-- CTE to get "Action" films and their rental count
	action_films AS (
	    SELECT
	        f.film_id,
	        f.title,
	        COUNT(r.rental_id) AS rental_count
	    FROM film f
	    INNER JOIN film_category fc USING(film_id)
	    INNER JOIN category c USING(category_id)
	    INNER JOIN inventory i USING(film_id)
	    INNER JOIN rental r USING(inventory_id)
	    WHERE c.name = 'Action'
	    GROUP BY f.film_id, f.title
	),
	-- CTE to calculate the average rental count across all films
	avg_rental_count AS (
	    SELECT AVG(rental_count)
	    FROM (SELECT COUNT(r.rental_id) AS rental_count
	          FROM rental r
	          INNER JOIN inventory i USING(inventory_id)
	          GROUP BY i.film_id) AS rental_counts
	)
	
	SELECT 
	    af.title,
	    sp.sales,
	    sp.avg_payment_amount,
	    (SELECT * FROM avg_sales_across_all_films) AS avg_sales_across_all_films
	FROM 
	    action_films af
	INNER JOIN sales_and_avg_payment_amount sp USING(film_id)
	WHERE 
	    af.rental_count > (SELECT * FROM avg_rental_count)
	ORDER BY sp.sales DESC;
	