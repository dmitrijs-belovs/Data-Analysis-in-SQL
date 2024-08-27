-- ORDER BY
	-- Return film titles, their rental count, and row number based on rental count
	SELECT
		f.title,
		COUNT(rental_id),
		ROW_NUMBER() OVER(ORDER BY COUNT(rental_id) DESC) AS row_number
	FROM film f
	INNER JOIN inventory i USING(film_id)
	INNER JOIN rental r USING(inventory_id)
	GROUP BY f.title;

-- PARTITION BY
	-- Return top 3 most rented movies in each rented film category
	SELECT *
	FROM (SELECT
		       c.name,
		       f.title,
		       COUNT(rental_id),
		       ROW_NUMBER() OVER(PARTITION BY c.name ORDER BY COUNT(rental_id) DESC) AS rank
	      FROM
		       category c
	      INNER JOIN film_category fc USING(category_id)
	      INNER JOIN film f USING(film_id)
	      INNER JOIN inventory i USING(film_id)
	      INNER JOIN rental r USING(inventory_id)
	      GROUP BY c.name, f.title)
	WHERE rank <= 3
	ORDER BY rank;

-- Fetching with LAG, LEAD, FIRST_VALUE and LAST_VALUE
	-- Return the average time between consecutive rentals for each customer in ascending order
	SELECT
		customer_id,
		AVG(rental_date - previous_rental_date) AS avg_time_between_rentals
	FROM (SELECT
		       customer_id,
		       rental_id,
		       inventory_id,
		       rental_date,
		 LAG(rental_date, 1) OVER(PARTITION BY customer_id ORDER BY rental_date) AS previous_rental_date
		 FROM rental)
	GROUP BY customer_id
	ORDER BY avg_time_between_rentals;

	-- (The same result as in the previous query with LAG but now with LEAD)
	SELECT
		customer_id,
		AVG(next_rental_date - rental_date) AS avg_time_between_rentals
	FROM (SELECT
		       customer_id,
		       rental_id,
		       inventory_id,
		       rental_date,
		 LEAD(rental_date, 1) OVER(PARTITION BY customer_id ORDER BY rental_date) AS next_rental_date
		 FROM rental)
	GROUP BY customer_id
	ORDER BY avg_time_between_rentals;

	-- Return customers IDs and their first rental date in ascending order (newest customers first)
	SELECT DISTINCT
		customer_id,
		FIRST_VALUE(rental_date) 
		OVER(PARTITION BY customer_id ORDER BY rental_date) AS newest_customers
	FROM rental
	ORDER BY newest_customers DESC;

	-- Return customers IDs and their last rental date in descending order (customers who have been inactive the longest appear first)
	SELECT DISTINCT
		customer_id,
		LAST_VALUE(rental_date) 
		OVER(PARTITION BY customer_id ORDER BY rental_date 
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS inactive_customers
	FROM rental
	ORDER BY inactive_customers ASC;

-- Ranking with ROW_NUMBER, RANK, RANK_DENSE
	-- Return film titles, their rental count, and row number, rank, and dense rank based on rental count
	SELECT
		f.title,
		COUNT(rental_id),
		ROW_NUMBER() OVER(ORDER BY COUNT(rental_id) DESC) AS row_number,
		RANK() OVER(ORDER BY COUNT(rental_id) DESC) AS rank,
		DENSE_RANK() OVER(ORDER BY COUNT(rental_id) DESC) AS dense_rank
	FROM film f
	INNER JOIN inventory i USING(film_id)
	INNER JOIN rental r USING(inventory_id)
	GROUP BY f.title;

-- Paging
	-- Return all rented film titles, their sales and categorize them into 3 equal ranked groups using NTILE
	SELECT
		f.title,
		SUM(p.amount) AS sales,
		NTILE(3) OVER(ORDER BY SUM(p.amount)) AS sales_ntile
	FROM film f
	INNER JOIN inventory i USING(film_id)
	INNER JOIN rental r USING(inventory_id)
	INNER JOIN payment p USING(rental_id)
	GROUP BY f.title
	ORDER BY sales;

-- Aggregate window function and frames
	/* Return all rented film titles, their payment dates, and minimum, maximum, and cumulative sum of payment amount, 
       up to the current row (which is filtered to 2007-03-14) for each title */
	SELECT 
	    f.title,
		payment_date,
	    MIN(p.amount) OVER(PARTITION BY f.title ORDER BY p.payment_date) AS min_amount,
	    MAX(p.amount) OVER(PARTITION BY f.title ORDER BY p.payment_date) AS max_amount,
	    SUM(p.amount) OVER(PARTITION BY f.title ORDER BY p.payment_date) AS cumulative_sum
	FROM film f
	INNER JOIN inventory i USING(film_id)
	INNER JOIN rental r USING(inventory_id)
	INNER JOIN payment p USING(rental_id)
	WHERE p.payment_date < '2007-03-14'
	ORDER BY f.title, p.payment_date;

	/* Return all rented film titles, their rental dates, IDs, payment amount, and 
	   payment amount moving averages and cumulative totals based on 2 preceding rows 
	   and the current row for each film title */
	SELECT
		title,
		rental_date,
		rental_id,
		amount,
		ROUND(AVG(amount) OVER(PARTITION BY title ORDER BY row_number RANGE BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS 3_,
		SUM(amount) OVER(PARTITION BY title ORDER BY row_number RANGE BETWEEN 2 PRECEDING AND CURRENT ROW) AS 
	FROM 
		(SELECT
			f.title,
			r.rental_date,
			r.rental_id,
			p.amount,
			ROW_NUMBER() OVER(PARTITION BY f.title ORDER BY r.rental_date) as row_number
		FROM film f
		INNER JOIN inventory i USING(film_id)
		INNER JOIN rental r USING(inventory_id)
		INNER JOIN payment p USING(rental_id)
		ORDER BY f.title, r.rental_date);

-- Pivoting
	-- Pivot rental count data to display the number of rentals for each film category across different stores.
	CREATE EXTENSION IF NOT EXISTS tablefunc;	

	SELECT *
	FROM crosstab($$
	    SELECT
	        c.name,
	        i.store_id,
	        COUNT(r.rental_id) AS rental_count
	    FROM rental r
	    INNER JOIN inventory i USING(inventory_id)
	    INNER JOIN film f USING(film_id)
	    INNER JOIN film_category fc USING(film_id)
	    INNER JOIN category c USING(category_id)
	    GROUP BY c.name, i.store_id
	    ORDER BY c.name, i.store_id
    $$,
    $$ SELECT DISTINCT store_id FROM inventory ORDER BY store_id $$
	) AS pivot_table(name TEXT,
    	             store_1 INTEGER,
    	             store_2 INTEGER);

-- ROLLUP and CUBE
	-- Return rental counts aggregated by store and category, including subtotals and a grand total.
		SELECT
	        i.store_id,
			c.name,
	        COUNT(r.rental_id) AS rental_count
	    FROM rental r
	    INNER JOIN inventory i USING(inventory_id)
	    INNER JOIN film f USING(film_id)
	    INNER JOIN film_category fc USING(film_id)
	    INNER JOIN category c USING(category_id)
	    GROUP BY ROLLUP(i.store_id, c.name)
	    ORDER BY i.store_id, c.name;

		-- Return rental counts for all combinations of store and category, including all possible subtotals and a grand total.
		SELECT
	        i.store_id,
			c.name,
	        COUNT(r.rental_id) AS rental_count
	    FROM rental r
	    INNER JOIN inventory i USING(inventory_id)
	    INNER JOIN film f USING(film_id)
	    INNER JOIN film_category fc USING(film_id)
	    INNER JOIN category c USING(category_id)
	    GROUP BY CUBE(i.store_id, c.name)
	    ORDER BY i.store_id, c.name;

