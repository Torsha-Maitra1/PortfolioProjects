-- creating the database

create database netflix_project;

-- creating the main table

use netflix_project;
drop table if exists netflix;
create table netflix (
	show_id varchar(10),
    type varchar(10),
    title varchar(255),
    director varchar(255),
    cast text,
    country varchar(255),
    date_added varchar(50),
    release_year int,
    rating varchar(20),
    duration varchar(50),
    listed_in text,
    description text );
    
-- Loading the CSV File

    load data local infile 'C:/Users/Mis/OneDrive/Desktop/netflix_titles.csv'
    into table netflix
    fields terminated by ','
    enclosed by '"'
    lines terminated by '\n'
    ignore 1 rows
    ( @show_id, @type, @title, @director, @cast, @country, @date_added, @release_year, @rating, @duration, @listed_in, @description)
    set
		show_id = @show_id,
        type = @type,
        title = @title,
        director = @director,
        cast = @cast,
        country = @country,
        date_added = @date_added,
        release_year = @release_year,
        rating = @rating,
        duration = @duration,
        listed_in = @listed_in,
        description = @description;
        
-------------------------------------------------------------------------------
-- Data Cleaning and Transformation
-------------------------------------------------------------------------------

-- Convert date_added to proper datatype

alter table netflix add column
date_added_clean date;
UPDATE netflix
SET date_added_clean = STR_TO_DATE(TRIM(date_added), '%M %d, %Y')
WHERE date_added IS NOT NULL AND date_added <> '';

-- Extract year from date_added_clean

Alter table netflix add column
year_added int;
update netflix set year_added = year(date_added_cleaN);

select * from netflix;

---------------------------------------------------------------------------
-- Analytical Views for PowerBI
---------------------------------------------------------------------------

-- Movies vs TV Shows

create or replace view vw_type_count as
select type, count(*) as total_count
from netflix
where type is not null
group by type;

select * from vw_type_count;

-- Titles Added Over the Years

create or replace view vw_content_per_year as
select year_added, count(*) as total_content_added
from netflix
where year_added is not null
group by year_added
order by count(*) desc;
-- limit 5;

select * from vw_content_per_year;

-- Top 5 Countries by Content

create or replace view vw_top_countries as 
SELECT jt.country_name, COUNT(*) AS count
FROM netflix
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(country, ', ', '","'), '"]'),
    '$[*]' COLUMNS (country_name VARCHAR(100) PATH '$')
) AS jt
WHERE country IS NOT NULL AND country <> ''
GROUP BY jt.country_name
ORDER BY count DESC
LIMIT 5;

select * from vw_top_countries;

-- Top 5 Genres

create or replace view vw_genre as
SELECT jt.genre, COUNT(*) AS count
FROM netflix
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(listed_in, ', ', '","'), '"]'),
    '$[*]' COLUMNS (genre VARCHAR(100) PATH '$')
) AS jt
WHERE listed_in IS NOT NULL AND country <> ''
GROUP BY jt.genre
ORDER BY count DESC
LIMIT 5;

select * from vw_genre;

-- Top 5 Directors by Number of Contents

create or replace view vw_top_directors_number as
with top_directors_numbers as (select director, count(*) as total_content 
from netflix
where director is not null and director <> ''
group by director
order by count(*) desc),
top_directors_rank_number as(select director, total_content,
	   dense_rank() over(order by total_content desc) as rank_director
from top_directors_numbers)
select director, total_content, rank_director
from top_directors_rank_number
where rank_director <= 5;

select * from vw_top_directors_number;

-- Movie Popularity by Duration

create or replace view movie_popularity_duration as
with duration_movie as (SELECT title,
	   CAST(REGEXP_SUBSTR(duration, '[0-9]+') AS UNSIGNED) AS duration_min
FROM netflix
WHERE type = 'Movie' and duration is not null and duration <> '')
select 
	case 
		when duration_min < 60 then '<60 mins'
        when duration_min > 60 and duration_min <=120 then '60-120 mins'
        when duration_min > 120 and duration_min <= 180 then '120-180 mins'
        when duration_min > 180 then '>180 mins'
	end as duration_bin,
count(*) as total_count
from duration_movie
-- where duration_bin is not null
group by duration_bin
limit 4;

select * from movie_popularity_duration;

-- TV Shows Popularity by Duration

create or replace view vw_tv_popularity_duration as
with season_tv as (SELECT title,
	   CAST(REGEXP_SUBSTR(duration, '[0-9]+') AS UNSIGNED) AS duration_season
FROM netflix
WHERE type = 'TV Show' and duration is not null and duration <> '')
select 
	case 
		when duration_season = 1 then 'Mini Series'
        when duration_season > 1 and duration_season <=3 then 'Regular'
        when duration_season >= 4 then 'Long Series'
	end as season_bin,
count(*) as total_count
from season_tv
-- where duration_bin is not null
group by season_bin
limit 4;

select * from vw_tv_popularity_duration;

-- Genre Trend Over Time

create or replace view vw_genre_trend_over_time as
WITH genre_split AS (
    SELECT 
        n.show_id,
        n.title,
        n.type,
        n.year_added,
        TRIM(jt.genre) AS genre
    FROM netflix AS n
    JOIN JSON_TABLE(
        CONCAT('["', REPLACE(n.listed_in, ', ', '","'), '"]'),
        '$[*]' COLUMNS (genre VARCHAR(100) PATH '$')
    ) AS jt
    WHERE n.year_added IS NOT NULL
),
top_genre as (SELECT 
    year_added,
    genre,
    COUNT(*) AS total_titles,
    dense_rank() over( partition by year_added order by count(*) desc) as rank_genre
FROM genre_split
GROUP BY year_added, genre)
select year_added, genre, total_titles
from top_genre
where rank_genre = 1;

select * from vw_genre_trend_over_time;

-------------------------------------------------------------------------------
-- Creating view for KPI Summary
-------------------------------------------------------------------------------

create or replace view vw_netflix_kpi_sum as
select 
	ROUND(AVG(CASE WHEN type = 'Movie' 
                   THEN CAST(REGEXP_SUBSTR(duration, '[0-9]+') AS UNSIGNED)
              END), 1) AS avg_movie_duration_min,
	ceil(AVG(CASE WHEN type = 'TV Show' 
                   THEN CAST(REGEXP_SUBSTR(duration, '[0-9]+') AS UNSIGNED)
              END)) AS avg_tvshow_seasons,
    (
        SELECT COUNT(DISTINCT TRIM(jt.genre))
        FROM netflix n
        JOIN JSON_TABLE(
            CONCAT('["', REPLACE(n.listed_in, ', ', '","'), '"]'),
            '$[*]' COLUMNS (genre VARCHAR(100) PATH '$')
        ) AS jt
        WHERE jt.genre IS NOT NULL AND jt.genre <> ''
    ) AS total_unique_genres,
    (
        SELECT TRIM(jt.genre)
        FROM netflix n
        JOIN JSON_TABLE(
            CONCAT('["', REPLACE(n.listed_in, ', ', '","'), '"]'),
            '$[*]' COLUMNS (genre VARCHAR(100) PATH '$')
        ) AS jt
        GROUP BY jt.genre
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS top_genre_overall
from netflix;

select * from vw_netflix_kpi_sum;
    
