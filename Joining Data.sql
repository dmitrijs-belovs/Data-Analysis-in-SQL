-- INNER JOIN
	-- Return all rented film titles and their rental count and sales
	SELECT
		f.title,
		COUNT(r.rental_id) AS rental_count,
		SUM(p.amount) AS sales
	FROM film f
	INNER JOIN inventory i USING(film_id)
	INNER JOIN rental r USING(inventory_id)
	INNER JOIN payment p USING(rental_id)
	GROUP BY f.title
	ORDER BY rental_count DESC, sales DESC;

-- LEFT JOIN
	-- Return all film titles that are available in inventory but have never been rented
	SELECT f.title
	FROM film f
	LEFT JOIN inventory i USING(film_id)
	LEFT JOIN rental r USING(inventory_id)
	WHERE rental_id IS NULL
	ORDER BY title;

-- RIGHT JOIN
	-- Return all invenotries that don't have film titles
	SELECT f.title
	FROM film f
	RIGHT JOIN inventory i USING(film_id)
	WHERE f.title IS NULL
	ORDER BY f.title;

-- FULL JOIN
	/* Return all film titles that are not available in inventory or have never been rented,
	   or inventories or rentals that don't have titles */
	SELECT
	    f.title,
	    i.inventory_id,
	    r.rental_id
	FROM film f
	FULL OUTER JOIN inventory i USING(film_id)
	FULL OUTER JOIN rental r USING(inventory_id)
	WHERE f.title IS NULL OR i.inventory_id IS NULL OR r.rental_id IS NULL;

-- CROSS JOIN
	-- Return all possible combinations of customer IDs and films that they have never rented
	SELECT
		c.customer_id,
		f.title
	FROM customer c
	CROSS JOIN film f
	LEFT JOIN inventory i USING(film_id)
	LEFT JOIN rental r USING(inventory_id)
	WHERE rental_id IS NULL
	ORDER BY c.customer_id, f.title;

-- SELF JOIN
	-- Return customers who rented multiple films at the same time
	SELECT DISTINCT
	    r1.customer_id,
		r1.rental_date,
		LEAST(r1.inventory_id, r2.inventory_id) AS inventory_id_1,
    	GREATEST(r1.inventory_id, r2.inventory_id) AS inventory_id_2
	FROM 
	    rental r1
	INNER JOIN 
	    rental r2 ON r1.customer_id = r2.customer_id 
	             AND r1.rental_date = r2.rental_date
                 AND r1.inventory_id <> r2.inventory_id
	ORDER BY 
	    r1.customer_id, r1.rental_date;

/* Create 2 temporary tables for the following union, intersect and except queries 
   with top most rented films for store 1 and for store 2 */

CREATE TEMP TABLE top_rented_films_in_store1 AS(
	SELECT
	    f.title,
	    COUNT(r.rental_id) AS rental_count
	FROM film f
	INNER JOIN inventory i USING(film_id)
	INNER JOIN rental r USING(inventory_id)
	WHERE i.store_id = 1
	GROUP BY f.title
	ORDER BY rental_count DESC
	LIMIT 50
);

CREATE TEMP TABLE top_rented_films_in_store2 AS(
	SELECT
	    f.title,
	    COUNT(r.rental_id) AS rental_count
	FROM film f
	INNER JOIN inventory i USING(film_id)
	INNER JOIN rental r USING(inventory_id)
	WHERE i.store_id = 2
	GROUP BY f.title
	ORDER BY rental_count DESC
	LIMIT 50
);

-- UNION
	-- Return top 50 most rented films in store 1 and 2 
	SELECT * 
	FROM top_rented_films_in_store1
	
	UNION ALL
	
	SELECT * 
	FROM top_rented_films_in_store2;

-- INTERSECT
	-- Return rented films that are top 50 in both store 1 and 2
	SELECT * 
	FROM top_rented_films_in_store1
	
	INTERSECT
	
	SELECT * 
	FROM top_rented_films_in_store2;

-- EXCEPT
	-- Return rented films that are top 50 in store 1 and not in store 2
	SELECT * 
	FROM top_rented_films_in_store1
	
	EXCEPT
	
	SELECT * 
	FROM top_rented_films_in_store2;
