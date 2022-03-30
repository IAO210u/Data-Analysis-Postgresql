CREATE IF NOT EXISTS DATABASE portfolioproject
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Chinese (Simplified)_China.936'
    LC_CTYPE = 'Chinese (Simplified)_China.936'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;


--  Create tables
CREATE IF NOT EXISTS TABLE netflix_title (
	duration_minutes varchar(32767),
	duration_seasons varchar(32767),
	"type" varchar(32767),
	title varchar(32767),
	date_added varchar(32767),
	release_year varchar(32767),
	rating varchar(32767),
	description text,
	show_id varchar(32767)
);


CREATE TABLE IF NOT EXISTS netflix_countries (
	country varchar(32767),
	show_id varchar(32767)
);


CREATE IF NOT EXISTS TABLE netflix_categories (
	listed_in varchar(32767),
	show_id varchar(32767)
);

-- Import data
COPY netflix_title
FROM '\dataset\netflix_title.csv'
Delimiter ','
CSV HEADER;

COPY netflix_countries
FROM '\dataset=[po]0i]\netflix_countries.csv'
Delimiter ','
CSV HEADER;

COPY netflix_categories
FROM '\dataset\netflix_categories.csv'
Delimiter ','
CSV HEADER;





-------------------------------Query----------------------------------------------------
----------------------------------------------------------------------------------------
-- SUM the up movies each year 
SELECT 
country, release_year, CAST(COUNT(t.show_id) as numeric) movies, SUM(COUNT(t.show_id))
OVER(PARTITION BY release_year) as total_movies
FROM 
	netflix_countries as c
JOIN 
	netflix_title as t
ON 
	c.show_id=t.show_id
WHERE 
	date_added IS NOT NULL
AND
	country is NOT NULL
AND 
	type LIKE 'M%'
GROUP BY country, release_year
ORDER BY 2 DESC, 1 DESC;




-- count the movie of each country by year, and their portion by the total number of movies each year
SELECT 
*, ROUND((foo.movies/foo.annual_total_movies)*100,2) || '%' as Percentage  
FROM 
	(SELECT 
			country, release_year, CAST(COUNT(t.show_id) as numeric) movies, SUM(COUNT(t.show_id)) 
			OVER(PARTITION BY release_year) as annual_total_movies
		FROM 
			netflix_countries as c
		JOIN 
			netflix_title as t
		ON 
			c.show_id=t.show_id
		WHERE 
			date_added IS NOT NULL
		AND 
			type LIKE 'M%'
		GROUP BY country, release_year
	) foo
		ORDER BY 2 DESC, 3 DESC
;


	

--------PROBLEM data-----------------
select country, RIGHT(country,1) from sheet1
WHERE RIGHT(country,1) !~* '^.*[A-Z]$' --!for not, ~for match, *for case insenstive
ORDER BY 2;

select DISTINCT country from netflix_countries
WHERE country LIKE '%Germany'
ORDER BY 1 DESC  


	
-- Data Cleaning----
----- Update the incorrect data from table 
UPDATE netflix_countries
SET country = CASE WHEN RIGHT(country,1) !~* '^.*[A-Z]$' THEN left(country,length(country)-1)
	ELSE country
	END

WITH foo AS (
SELECT 
	DISTINCT(CASE WHEN country LIKE '%Germany' THEN 'Germany'
		ELSE country
		END) AS country, 
		release_year, CAST(COUNT(t.show_id) as numeric) movies, SUM(COUNT(t.show_id)) 
		OVER(PARTITION BY release_year) as annual_total_movies
FROM 
		netflix_countries as c
	JOIN 
			netflix_title as t
	ON 
		c.show_id=t.show_id
	WHERE 
		date_added IS NOT NULL
	AND 
		type LIKE 'M%'
	GROUP BY country,  release_year)
SELECT 
*, ROUND((foo.movies/foo.annual_total_movies)*100,2) || '%' as Percentage  
FROM 
	foo
ORDER BY 2 DESC, 3 DESC


-- View
DROP VIEW sheet1 -- drop view first
CREATE OR REPLACE VIEW sheet1 AS
--- "CREATE OR REPLACE" equals to "CREATE IF NOT EXISTS"
	WITH foo AS (
	SELECT 
		DISTINCT(CASE WHEN country LIKE '%Germany' THEN 'Germany'
			ELSE country
			END) AS country, 
			release_year, CAST(COUNT(t.show_id) as numeric) movies, SUM(COUNT(t.show_id)) 
			OVER(PARTITION BY release_year) as annual_total_movies
	FROM 
			netflix_countries as c
		JOIN 
				netflix_title as t
		ON 
			c.show_id=t.show_id
		WHERE 
			date_added IS NOT NULL
		AND 
			type LIKE 'M%'
		GROUP BY country,  release_year)
SELECT 
    *, ROUND((foo.movies/foo.annual_total_movies)*100,2) || '%' as Percentage  
FROM 
	foo
ORDER BY 2 DESC, 3 DESC;


--Export data

copy sheet1 to '\dataset\sheet1.csv' CSV HEADER;




