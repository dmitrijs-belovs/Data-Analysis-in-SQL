# Data-Analysis-in-SQL

## Introduction

This repository contains a demonstration of my PostgreSQL skills learned in the [Associate Data Analyst in SQL](https://www.datacamp.com/tracks/associate-data-analyst-in-sql) course from DataCamp. I use the popular Postgres sample database Pagila, which represents a DVD rental store, containing information about films, rental stores and rentals, where a customer rents a film from a store through its staff ([link to the ERD](https://github.com/dmitrijs-belovs/Data-Analysis-in-SQL/blob/main/dvdrental_ERD.pdf)). I restore it in pgAdmin4 with a downloaded [backup file](https://github.com/dmitrijs-belovs/Data-Analysis-in-SQL/blob/main/dvdrental.tar) and sequentially go over all concepts learned in the course, beginning with simple queries such as selecting the data and progressing to more advanced ones such as joining the data, case statements, subqueries and CTEs, window functions, arrays, and functions for manipulating the data. I analyze films, rentals, sales and revenue, employee and store performance, customer preferences, and inventory. I do not conduct complete data analysis on any of these topics, but choose among them for the most appropriate when practicing different concepts.

## Selecting Data

<details>
  <summary>Click to expand SQL code</summary>

```sql

-- Selecting one column from a table
	-- Return the title column from the film table
	SELECT title
	FROM film;

-- Selecting multiple columns from a table
	-- Return title, release_year, description, length, and rating columns from the film table
	SELECT
		title,
		release_year,
		description,
		length,
		rating
	FROM film;

-- Selecting all columns from a table
	-- Return all columns from the rental table
	SELECT *
	FROM rental;

-- Limiting output
	-- Return all columns from the rental table but limit output to 10 rows
	SELECT *
	FROM rental
	LIMIT 10;

-- Selecting unique values from a column
	-- Return unique values of staff_id column from the rental table
	SELECT DISTINCT staff_id AS unique_staff_ids
	FROM rental;

-- Filtering records based on a numeric condition
	-- Return all columns from the payment table, including only those payments where staff_id was 1
	SELECT *
	FROM payment
	WHERE staff_id = 1;

-- Filtering records based on multiple numeric conditions
	/* Return all columns from the payment table, including only those payments where staff_id was 1 and 
	   the amount was greater than or equal to 5 only */
	SELECT *
	FROM payment
	WHERE staff_id = 1 AND amount >= 5;

-- Filtering records based on textual condition
	-- Return all columns from the film table, including only those films with the word "Scientist" in description
	SELECT *
	FROM film
	WHERE description LIKE '%Scientist%';

-- Aggregate functions
	-- Return rental count, minimum, maximum and average payment amount, and total sales
	SELECT
		COUNT(*) AS rental_count,
		MIN(amount) AS min_amount,9
		MAX(amount) AS max_amount,
		ROUND(AVG(amount), 2) AS avg_amount,
		SUM(amount) AS sum_amount
	FROM payment;

-- Arithmetic with +, -, * or /
	-- Return the average rental duration
	SELECT AVG(return_date - rental_date) AS avg_rental_duration
	FROM rental;

-- Grouping and sorting
	-- Return rental count by staff_id in descending order
	SELECT
		staff_id,
		COUNT(*) AS rental_count
	FROM payment
	GROUP BY staff_id
	ORDER BY rental_count DESC;

-- Filtering grouped data
	-- Return rental count for each customer ID in descending order, including only those with 30 or more rentals
	SELECT
		customer_id,
		COUNT(*) AS rental_count
	FROM payment
	GROUP BY customer_id
	HAVING COUNT(*) >= 30
	ORDER BY rental_count DESC;

 ```

</details>

## Joining Data

<details>
  <summary>Click to expand SQL code</summary>
  
```sql

-- Inner join
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

-- Left join
	-- Return all film titles that are available in inventory but have never been rented
	SELECT f.title
	FROM film f
	LEFT JOIN inventory i USING(film_id)
	LEFT JOIN rental r USING(inventory_id)
	WHERE rental_id IS NULL
	ORDER BY title;

-- Right join
	-- Return all invenotries that don't have film titles
	SELECT f.title
	FROM film f
	RIGHT JOIN inventory i USING(film_id)
	WHERE f.title IS NULL
	ORDER BY f.title;

-- Full join
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

-- Cross join
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

-- Self join
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

-- Union
	-- Return top 50 most rented films in store 1 and 2 
	SELECT * 
	FROM top_rented_films_in_store1
	
	UNION ALL
	
	SELECT * 
	FROM top_rented_films_in_store2;

-- Intersect
	-- Return rented films that are top 50 in both store 1 and 2
	SELECT * 
	FROM top_rented_films_in_store1
	
	INTERSECT
	
	SELECT * 
	FROM top_rented_films_in_store2;

-- Except
	-- Return rented films that are top 50 in store 1 and not in store 2
	SELECT * 
	FROM top_rented_films_in_store1
	
	EXCEPT
	
	SELECT * 
	FROM top_rented_films_in_store2;

```

</details>

## Data Manipulation, Subqueries and CTEs

<details>
  <summary>Click to expand SQL code</summary>

```sql

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


```

</details>

## Window Functions

<details>
  <summary>Click to expand SQL code</summary>

```sql

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

```

</details>

## Arrays and Functions for Manipulating Data

<details>
  <summary>Click to expand SQL code</summary>

```sql

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

 ```

</details>
