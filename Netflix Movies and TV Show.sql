--NETFLIX MOVIES AND TV SHOW DURING 2008-2021
--prepare the table by setting the data type for each column in the data
create table netflix(
show_id varchar(10) primary key,
type varchar(10),
title text,
director text,
actors text,
country text,
date_added date,
release_year int,
rating varchar(10),
duration text,
listed_in text,
description text
);

--insert data from dataset into database
copy netflix
from 'C:\Program Files\PostgreSQL\17\data\netflix_dataset.csv'
delimiter ','
csv header;

--checking the data structure
select*from netflix
limit 10;

--checking for duplicates
select show_id, count(*) 
from netflix
group by show_id
order by show_id desc;

--checking whether there are missing values in each column
select
	count(*) filter(where show_id is null) as show_id_null,
	count(*) filter(where type is null) as type_null,
	count(*) filter(where title is null) as title_null,
	count(*) filter(where director is null) as director_null,
	count(*) filter(where actors is null) as actors_null,
	count(*) filter(where country is null) as country_null,
	count(*) filter(where date_added is null) as date_added_null,
	count(*) filter(where release_year is null) as release_year_null,
	count(*) filter(where rating is null) as rating_null,
	count(*) filter(where duration is null) as duration_null,
	count(*) filter(where listed_in is null) as listed_in_null,
	count(*) filter(where description is null) as description_null
from netflix;
	
--overcome missing values by labeling them 'Unknown'
update netflix
set director = 'Unknown'
where director is null;

update netflix
set actors = 'Unknown'
where actors is null;

update netflix
set country = 'Unknown'
where country is null;

UPDATE netflix a
SET date_added = (
  SELECT b.date_added
  FROM netflix b
  WHERE b.show_id < a.show_id AND b.date_added IS NOT NULL
  ORDER BY b.show_id DESC
  LIMIT 1
)
WHERE a.date_added IS NULL;

update netflix
set rating = 'Unknown'
where rating is null;

update netflix
set duration = 'Unknown'
where duration is null;

--saving the querys into csv format
copy netflix
to 'C:\Program Files\PostgreSQL\17\data\Netflix_Cleaned.csv'
delimiter ','
csv header;


--CHALLENGE--

select*from netflix;

--looking for the most productive directors for each movie and tv show category
select distinct director, 
count(type) over(partition by director) as total
from netflix
where type = 'Movie' and director <> 'Unknown'
order by total desc
limit 10;

select distinct director, 
count(type) over(partition by director) as total
from netflix
where type = 'TV Show' and director <> 'Unknown'
order by total desc
limit 10;

--movie vs tv show proportion
SELECT type, COUNT(*) AS jumlah
FROM netflix
GROUP BY type;

--distribution of release years of films from year to year that air on netflix
select distinct release_year,
count(*) over(partition by release_year) as total
from netflix
order by release_year asc;

--trend of adding content every year
select extract(year from date_added) as tahun,
count(*) as total 
from netflix
group by tahun
order by tahun;

--distribution based on rating
select distinct rating,
count(rating) over(partition by rating) as total
from netflix
order by total desc;

--What TV programs are airing in 2021?
select title, description
from netflix
where (select extract(year from date_added)) as year_added = 2021

--actor with the most movies/tv shows
select individual_actor, count(*) as appearances
from (
	select unnest(string_to_array(actors,',')) as individual_actor
	from netflix
	) as expanded
where individual_actor != 'Unknown'
group by individual_actor
order by appearances desc
limit 10;

--any movie from united states? include description too
select distinct show_id, title, description
from (
	select show_id, title, description, unnest(string_to_array(country,',')) as origin_country from netflix
	) as expanded
where origin_country = 'United States';

--what are the titles and what year did it start airing for the comedy genre (listed_in) and the rating is TV-MA
select title, year_added
from (
	select title, rating, extract(year from date_added) as year_added, unnest(string_to_array(listed_in,',')) as genre from netflix
) as expanded
where genre = 'Comedies' and rating = 'TV-MA';