------------PROBLEM DATA--------------
select 
show_id, duration_minutes, rating
from netflix_title
WHERE show_id IS NULL
AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' = FALSE)
OR rating IS NULL
ORDER BY 1 DESC

----------- eliminate common key ---------------
SELECT * FROM netflix_categories c
LEFT JOIN netflix_title t USING (show_id)
-- or
SELECT * FROM netflix_categories c
NATURAL JOIN netflix_title t

-- To find null values: Remove NOT in WHERE clause
-- FIND Redundant data
SELECT COUNT(c.show_id),
c.show_id
FROM netflix_categories c 
LEFT JOIN netflix_title t USING (show_id)
WHERE TYPE LIKE 'M%'
AND c.show_id IS NOT NULL
AND rating IS NOT NULL
AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' = TRUE)
GROUP BY c.show_id
HAVING count(c.show_id) > 1
ORDER BY 1 DESC

-- Since we have agg_func CAST(), use ROW_NUMBER() instead of COUNT()
-- Another way to find duplicates
WITH foo AS(
SELECT
	ROW_NUMBER() OVER (PARTITION BY show_id) AS rn,  
	CAST(duration_minutes AS INTEGER), c.ctid, * 
	FROM netflix_categories c 
LEFT JOIN netflix_title t USING (show_id)
WHERE TYPE LIKE 'M%'
AND c.show_id IS NOT NULL
AND rating IS NOT NULL
AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' IS TRUE)
)
SELECT foo.ctid, * FROM foo ORDER BY 3 DESC, 2 DESC -- foo.ctid == c.ctid



----- QUERY-----------
-- Join without duplicates
-- use CASE WHEN to modify category'Movies' to 'Others'
WITH foo AS(
SELECT DISTINCT ON(show_id, title, duration)
	CASE WHEN listed_in = 'Movies' THEN 'Others'
	ELSE listed_in END categories,
	c.ctid, 
	duration_minutes::integer AS duration, *, 
	LEFT(date_added,4) year_added
	FROM netflix_categories c 
LEFT JOIN netflix_title t USING (show_id)
WHERE TYPE LIKE 'M%'
AND c.show_id IS NOT NULL
AND rating IS NOT NULL
AND title IS NOT NULL
AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' IS TRUE)
)
SELECT * FROM foo
ORDER BY 3 DESC

-- The number of movies by categories and year added
-- DROP VIEW cats -- drop view if can't' replace view
CREATE OR REPLACE VIEW cats AS
	WITH foo AS(
	SELECT DISTINCT ON(show_id, title, duration)
		CASE WHEN listed_in = 'Movies' THEN 'Others'
		ELSE listed_in END categories,
		c.ctid, 
		duration_minutes::integer AS duration, *, 
		LEFT(date_added,4) year_added
		FROM netflix_categories c 
	LEFT JOIN netflix_title t USING (show_id)
	WHERE TYPE LIKE 'M%'
	AND c.show_id IS NOT NULL
	AND rating IS NOT NULL
	AND title IS NOT NULL
	AND (duration_minutes ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' IS TRUE)
	)
	SELECT 
	max_rn AS movies, categories, date_added, year_added, release_year, ROUND(rd) average_duration 
	FROM(
		SELECT 
		ROW_NUMBER() OVER (PARTITION BY categories, year_added) rn,
		COUNT(show_id) OVER (PARTITION BY categories, year_added) max_rn,
		categories, date_added, year_added, release_year, 
		AVG(duration) OVER (PARTITION BY categories, year_added) rd
		FROM foo ) cte
	WHERE rn = max_rn
	ORDER BY 1 DESC;

-- Export data
COPY (SELECT * FROM cats)
TO 'E:\DATA_MANAGEMENT\DataWarehouse\mov_cats.csv' CSV HEADER;




