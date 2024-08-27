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
