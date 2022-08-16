-- DATA Cleansing
------------PROBLEM DATA--------------
select 
rating, show_id, duration_minutes, release_year
from netflix_title
WHERE show_id IS NULL
AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' = FALSE)
OR rating IS NULL
OR release_year IS NULL
ORDER BY 2 DESC

-- Count duplicates
SELECT 
COUNT(show_id), show_id
FROM netflix_title t
WHERE TYPE LIKE 'M%'
AND show_id IS NOT NULL
AND rating IS NOT NULL
AND release_year IS NOT NULL
AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' = TRUE)
GROUP BY show_id
ORDER BY 1 DESC


-- Subquery: alternative for cte without `case when` statement
SELECT DISTINCT ON(show_id, title, number) 
show_id, CAST(duration_minutes AS INTEGER) as number, *
FROM netflix_title 
WHERE TYPE LIKE 'M%'
AND show_id IS NOT NULL
AND rating IS NOT NULL
AND release_year IS NOT NULL
AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' = TRUE)
ORDER BY number DESC


-- Using ROW_NUMBER() function with cte
WITH cte AS(
	SELECT 
	CASE 
		WHEN rating in ('TV-Y', 'TV-Y7', 'TV-Y7-FV', 'G', 'TV-G', 'PG', 'TV-PG') THEN 'Kids'
		WHEN rating in ('PG-13', 'TV-14') THEN 'Teens'
		WHEN rating in ('R', 'TV-MA', 'NC-17') THEN 'Adults'
		ELSE 'Unknown' END maturity_ratings,
	ROW_NUMBER() OVER (PARTITION BY show_id) AS rn,  
	CAST(duration_minutes AS INTEGER) mov_length, *
	FROM netflix_title 
	WHERE TYPE LIKE 'M%'
	AND show_id IS NOT NULL
	AND rating IS NOT NULL
	AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' = TRUE)
)

-----------------------------------------
------------- Create view ---------------
CREATE OR REPLACE VIEW rts AS(
	SELECT 
	CASE 
		WHEN rating in ('TV-Y', 'TV-Y7', 'TV-Y7-FV', 'G', 'TV-G', 'PG', 'TV-PG') THEN 'Kids'
		WHEN rating in ('PG-13', 'TV-14') THEN 'Teens'
		WHEN rating in ('R', 'TV-MA', 'NC-17') THEN 'Adults'
		ELSE 'Unknown' END maturity_ratings,
	ROW_NUMBER() OVER (PARTITION BY show_id) AS rn,  
	CAST(duration_minutes AS INTEGER) mov_length, *
	FROM netflix_title 
	WHERE TYPE LIKE 'M%'
	AND show_id IS NOT NULL
	AND rating IS NOT NULL
	AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' = TRUE)
)

-----------------------------------------------------------------
-- Analysis
-- simple.ver: overall information
SELECT 
maturity_ratings, MAX(mov_length), MIN(mov_length), ROUND(AVG(mov_length)) average, count(show_id) toatl_movies
FROM rts
GROUP BY  maturity_ratings
ORDER BY 1 ASC

-- complex.ver: by year
SELECT 
maturity_ratings, 
MAX(mov_length) max_length, MIN(mov_length) min_length, ROUND(AVG(mov_length),2) average, count(show_id) toatl_movies, release_year 
FROM rts
GROUP BY maturity_ratings, release_year
ORDER BY 1 ASC, 6 DESC







------------ Data Visualization------------
------------Complex ver Breakdown: when constructing following, delete complex.ver
-- Start From this
SELECT 
maturity_ratings, MAX(mov_length), MIN(mov_length), ROUND(AVG(mov_length)) average, count(show_id) toatl_movies
FROM rts
GROUP BY  maturity_ratings
ORDER BY 1 ASC

-- THEN How many mvs each year by cates
-- A line chart first
SELECT count(show_id) movies, maturity_ratings, release_year 
FROM rts
GROUP BY  maturity_ratings, release_year
ORDER BY 3 DESC, 2 ASC

COPY (
	SELECT count(show_id) movies, maturity_ratings, release_year 
	FROM rts
	GROUP BY  maturity_ratings, release_year
	ORDER BY 3 DESC, 2 ASC)
TO 'E:\DATA_MANAGEMENT\DataWarehouse\mov_number_by_rt.csv' CSV HEADER;




-- The trend of movie length over the years, because it reflects audience's attitude toward movie
-- Start from this:
SELECT 
maturity_ratings, 
MAX(mov_length) max_length, MIN(mov_length) min_length, ROUND(AVG(mov_length)) average_length, release_year 
FROM rts
GROUP BY maturity_ratings, release_year
ORDER BY 1 ASC, 5 DESC

COPY  
	(SELECT 
	maturity_ratings, 
	MAX(mov_length) max_length, MIN(mov_length) min_length, ROUND(AVG(mov_length)) average_length, release_year 
	FROM rts
	GROUP BY maturity_ratings, release_year
	ORDER BY 1 ASC, 5 DESC)
TO 'E:\DATA_MANAGEMENT\DataWarehouse\mov_length.csv' CSV HEADER;


-- Adults
SELECT 
maturity_ratings, MAX(mov_length), MIN(mov_length), ROUND(AVG(mov_length)) average, release_year 
FROM rts WHERE maturity_ratings = 'Adults'
GROUP BY maturity_ratings, release_year
ORDER BY 5 DESC
-- Teens
SELECT 
maturity_ratings, MAX(mov_length), MIN(mov_length), ROUND(AVG(mov_length)) average, release_year 
FROM rts WHERE maturity_ratings = 'Teens'
GROUP BY maturity_ratings, release_year
ORDER BY 5 DESC
-- Kids
SELECT 
maturity_ratings, MAX(mov_length), MIN(mov_length), ROUND(AVG(mov_length)) average, release_year 
FROM rts WHERE maturity_ratings = 'Kids'
GROUP BY maturity_ratings, release_year
ORDER BY 5 DESC





-- Using ctid
SELECT 
COUNT(show_id), *
*/

SELECT SUM(c), maturity_ratings
FROM (
	SELECT count(show_id) c, maturity_ratings, release_year 
	FROM rts
	GROUP BY  maturity_ratings, release_year)  as foo
	GROUP BY maturity_ratings