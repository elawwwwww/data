// 1. Overload of content (i.w. how many shows per year)
WITH
subquery_lower_series_or_movie AS (SELECT COUNT(title) AS count_title, substr(netflix_release_date, 1, 4) AS netflix_release_year FROM hive.myschema.netflix WHERE title != '' GROUP by 2)
SELECT * FROM subquery_lower_series_or_movie ORDER BY 1 DESC


// 2. Netflix version of popularity
WITH
subquery_count AS (SELECT title, substr(netflix_release_date, 1, 4) AS netflix_release_year, actors,CASE WHEN country_availability IS NULL THEN 0 ELSE (LENGTH(country_availability)- LENGTH(REGEXP_REPLACE(country_availability,',')) +1) END AS count_country_availability FROM hive.myschema.netflix),
subquery_split_actors AS (SELECT title, netflix_release_year, lower(trim(split_b)) AS actor FROM subquery_count CROSS JOIN UNNEST(SPLIT(actors, ',')) AS t (split_b) WHERE count_country_availability > 10),
subquery_popularity_actor AS (SELECT actor, COUNT(title) AS count_actor FROM subquery_split_actors WHERE actor !='' GROUP BY 1),
subquery_title_popular_year AS (SELECT title, netflix_release_year, MAX(count_actor) AS count_popularity FROM subquery_split_actors a LEFT JOIN subquery_popularity_actor b ON a.actor=b.actor WHERE a.actor !='' GROUP BY 1, 2),
subquery_popularity_grade AS (SELECT netflix_release_year,
    SUM(CASE WHEN count_popularity <= 30 AND count_popularity > 20 THEN 1 ELSE 0 END) AS popularity_id,
    SUM(CASE WHEN count_popularity <= 20 AND count_popularity > 10 THEN 1 ELSE 0 END) AS popularity_grade_2,
    SUM(CASE WHEN count_popularity <= 10 AND count_popularity >= 0 THEN 1 ELSE 0 END) AS popularity_grade_1 FROM subquery_title_popular_year GROUP BY 1)

SELECT * FROM subquery_popularity_grade


// 3. IMDb Score version of popularity
WITH
subquery_imdb_score_no_null AS (SELECT title, substr(netflix_release_date, 1, 4) AS netflix_release_year, 
CAST((CASE WHEN imdb_score = '' THEN '0' ELSE imdb_score END) AS decimal(4,1)) AS imdb_score_no_null FROM hive.myschema.netflix),
subquery_imdb_score_grade AS (SELECT netflix_release_year,
    SUM(CASE WHEN imdb_score_no_null <= 10 AND imdb_score_no_null >= 9 THEN 1 ELSE 0 END) AS imdb_score__grade_5,
        CASE WHEN imdb_score_no_null < 9  AND imdb_score_no_null >= 8 THEN 1 ELSE 0 END
    SUM(CASE WHEN imdb_score_no_null < 8  AND imdb_score_no_null >= 7 THEN 1 ELSE 0 END) AS imdb_score_grade_4,
    SUM(CASE WHEN imdb_score_no_null < 7 AND imdb_score_no_null >= 6 THEN 1 ELSE 0 END) AS imdb_score_grade_3,
    SUM(CASE WHEN imdb_score_no_null < 6 AND imdb_score_no_null >=5 THEN 1 ELSE 0 END) AS imdb_score_grade_2,
    SUM(CASE WHEN imdb_score_no_null < 5 AND imdb_score_no_null >= 4 THEN 1 ELSE 0 END) AS imdb_score_grade_1 FROM subquery_imdb_score_no_null GROUP BY 1 ORDER BY 1 DESC)

SELECT * FROM subquery_imdb_score_grade


// 4. IMDb votes version of popularity
WITH subquery_format AS (
    SELECT
       title,
       substr(netflix_release_date, 1, 4) AS netflix_release_year,
       CASE WHEN imdb_votes=''
           THEN 0 ELSE
               COALESCE(CAST(split_part(imdb_votes, '.', 1) AS INT),0) END AS imdb_votes_formatted FROM hive.myschema.netflix)
,subquery_imdb_votes_summary_stats AS (
      SELECT
          MAX(imdb_votes_formatted) AS imdb_votes_max,
          approx_percentile(imdb_votes_formatted,0.75) AS imdb_votes_75,
          approx_percentile(imdb_votes_formatted,0.5) AS imdb_votes_50,
          approx_percentile(imdb_votes_formatted,0.25) AS imdb_votes_25,
          MIN(imdb_votes_formatted) AS imdb_votes_min
      FROM subquery_format
      WHERE imdb_votes_formatted != 0)
,subquery_popularity_grade AS (
    SELECT
        netflix_release_year,
        SUM(CASE WHEN imdb_votes_formatted < imdb_votes_25 AND imdb_votes_formatted >= imdb_votes_min THEN 1 ELSE 0 END) AS very_unpopular,
        SUM(CASE WHEN imdb_votes_formatted < imdb_votes_50 AND imdb_votes_formatted >= imdb_votes_25 THEN 1 ELSE 0 END) AS unpopular,
        SUM(CASE WHEN imdb_votes_formatted < imdb_votes_75 AND imdb_votes_formatted >= imdb_votes_50 THEN 1 ELSE 0 END) AS popular,
        SUM(CASE WHEN imdb_votes_formatted <= imdb_votes_max AND imdb_votes_formatted >= imdb_votes_75 THEN 1 ELSE 0 END) AS very_popular,
        SUM(CASE WHEN imdb_votes_formatted =0 THEN 1 ELSE 0 END) AS na
    FROM subquery_format CROSS JOIN subquery_imdb_votes_summary_stats
    GROUP BY 1)
SELECT * FROM subquery_popularity_grade


// 5. series VS movies over netflix_release_year
WITH
subquery_lower_series_or_movie AS (SELECT title, substr(netflix_release_date, 1, 4) AS netflix_release_year, lower(series_or_movie) AS lower_series_or_movie FROM hive.myschema.netflix WHERE lower(series_or_movie) != ''),
subquery_series_or_movie AS (SELECT netflix_release_year,  SUM(CASE WHEN lower_series_or_movie = 'series' THEN 1 ELSE 0 END) AS series,  SUM(CASE WHEN lower_series_or_movie = 'movie' THEN 1 ELSE 0 END) AS movie FROM subquery_lower_series_or_movie GROUP BY 1)
SELECT * FROM subquery_series_or_movie ORDER BY 1 DESC


WITH
subquery_split_tag AS (SELECT title, imdb_score, lower(trim(split_b)) AS tags_split FROM hive.myschema.netflix CROSS JOIN UNNEST(SPLIT(tags, ',')) AS t (split_b) WHERE imdb_score != ''),
subquery_split_tag_not_null AS (SELECT * FROM subquery_split_tag WHERE tags_split != '' or tags_split IS NOT NULL)

SELECT tags_split, COUNT(tags_split) AS count_tags_split, AVG(CAST(imdb_score AS decimal(4,2))) AS avg_imdb_score FROM subquery_split_tag_not_null GROUP BY 1


-- 6. Tag analysis
WITH
subquery_deduplication AS (SELECT DENSE_RANK() OVER (ORDER BY title, series_or_movie, director, release_date) AS netflix_id,* FROM hive.myschema.netflix),
subquery_split_tag AS (SELECT netflix_id,title, CAST((CASE WHEN imdb_score = '' THEN '0' ELSE imdb_score END) AS decimal(4,1)) AS imdb_score, lower(trim(split_b)) AS tags_split FROM subquery_deduplication CROSS JOIN UNNEST(SPLIT(tags, ',')) AS t (split_b) WHERE imdb_score != ''),
subquery_split_tag_not_null AS (SELECT * FROM subquery_split_tag WHERE tags_split!='' AND tags_split IS NOT NULL),
subquery_split_tag_space AS (
    SELECT netflix_id,title, imdb_score,tags_split,lower (trim (split_b)) AS tags_split_space
    FROM subquery_split_tag_not_null
    CROSS JOIN UNNEST(SPLIT(tags_split, ' ')) AS t (split_b)
    ),
--same netflix id means same title, same series_or_movie, same director and same release date
subquery_remove_dup AS(SELECT netflix_id,title, tags_split,tags_split_space, AVG(imdb_score) AS imdb_score FROM subquery_split_tag_space GROUP BY 1,2,3,4)
,sub AS(SELECT * FROM subquery_remove_dup WHERE netflix_id IN (12047,14792,12445))
SELECT netflix_id,title,tags_split,tags_split_space,AVG(imdb_score) FROM sub GROUP BY 1,2,3,4
}



// Genre analysis -- count title per genre
WITH
subquery_deduplication AS (SELECT DENSE_RANK() OVER (ORDER BY title, series_or_movie, director, release_date) AS netflix_id,* FROM hive.myschema.netflix),
subquery_split_genre AS (SELECT netflix_id,title, lower(trim(split_b)) AS genre_split, CAST((CASE WHEN imdb_score = '' THEN '0' ELSE imdb_score END) AS decimal(4,1)) AS imdb_score FROM subquery_deduplication CROSS JOIN UNNEST(SPLIT(genre, ',')) AS t (split_b)),
subquery_split_genre_not_null AS (SELECT * FROM subquery_split_genre WHERE genre_split!='' AND genre_split IS NOT NULL),
subquery_remove_dup AS(SELECT netflix_id,title, genre_split, AVG(imdb_score) AS imdb_score FROM subquery_split_genre_not_null GROUP BY 1,2,3)

SELECT genre_split, COUNT(netflix_id) AS count_netflix_id, AVG(imdb_score) AS avg_imdb_score FROM subquery_remove_dup GROUP BY 1 ORDER BY 2 DESC



// Genre analysis
WITH
subquery_deduplication AS (SELECT DENSE_RANK() OVER (ORDER BY title, series_or_movie, genre, director, release_date) AS netflix_id,* FROM hive.myschema.netflix),
subquery_split_genre AS (SELECT netflix_id,title, lower(trim(split_b)) AS genre_split, CAST((CASE WHEN imdb_score = '' THEN '0' ELSE imdb_score END) AS decimal(4,1)) AS imdb_score FROM subquery_deduplication CROSS JOIN UNNEST(SPLIT(genre, ',')) AS t (split_b)),
subquery_split_genre_not_null AS (SELECT * FROM subquery_split_genre WHERE genre_split!='' AND genre_split IS NOT NULL),
subquery_split_genre_space AS (
    SELECT netflix_id,title,imdb_score,genre_split,lower (trim (split_b)) AS genre_split_space
    FROM subquery_split_genre_not_null
    CROSS JOIN UNNEST(SPLIT(genre_split, ' ')) AS t (split_b)
    ),
subquery_remove_dup AS(SELECT netflix_id,title, genre_split,genre_split_space, AVG(imdb_score) AS imdb_score FROM subquery_split_genre_space GROUP BY 1,2,3,4)
SELECT netflix_id, title, COUNT(genre_split)AS count_genre FROM subquery_remove_dup GROUP BY 1, 2 ORDER BY 3 DESC


// Country availability analysis
WITH
subquery_deduplication AS (SELECT DENSE_RANK() OVER (ORDER BY title, series_or_movie, director, release_date) AS netflix_id,* FROM hive.myschema.netflix)
,subquery_count_country AS (SELECT netflix_id, title, CASE WHEN country_availability IS NULL THEN 0 ELSE (LENGTH(country_availability)- LENGTH(REGEXP_REPLACE(country_availability,',')) +1) END AS count_country_availability FROM subquery_deduplication)
,subquery_country_availabile_per_title AS (SELECT * FROM subquery_count_country)
,subquery_count_summary AS (SELECT count_country_availability, COUNT(netflix_id) AS count_title_per_countriesavailable FROM subquery_country_availabile_per_title GROUP BY 1)
SELECT MAX(count_title_per_countriesavailable), MIN(count_title_per_countriesavailable), approx_percentile(count_title_per_countriesavailable, 0.5) FROM subquery_count_summary


// IMDb score distribution
WITH
subquery_deduplication AS (SELECT DENSE_RANK() OVER (ORDER BY title, series_or_movie, director, release_date) AS netflix_id,*
FROM hive.myschema.netflix)
,subquery_imdb_score_count AS (SELECT netflix_id,title,
                                     CAST((CASE WHEN imdb_score = '' THEN '0' ELSE imdb_score END) AS decimal(4,1)) AS imdb_score
FROM subquery_deduplication)
,subquery_remove_dup AS(SELECT netflix_id, AVG(imdb_score) AS imdb_score
FROM subquery_imdb_score_count GROUP BY 1)
SELECT imdb_score, COUNT(netflix_id) FROM subquery_remove_dup GROUP BY 1 ORDER BY 1


// IMDb_votes distribution
WITH
subquery_deduplication AS (SELECT DENSE_RANK() OVER (ORDER BY title, series_or_movie, director, release_date) AS netflix_id,*
FROM hive.myschema.netflix)
,subquery_imdb_votes_count AS (SELECT netflix_id,title,
                                     CAST((CASE WHEN imdb_votes = '' THEN '0' ELSE SPLIT_PART(imdb_votes,'.', 1) END) AS INT) AS imdb_votes
FROM subquery_deduplication)
,subquery_remove_dup AS(SELECT netflix_id, AVG(imdb_votes) AS imdb_votes
FROM subquery_imdb_votes_count GROUP BY 1)
SELECT imdb_votes, COUNT(netflix_id) AS count_netflix_id FROM subquery_remove_dup GROUP BY 1 ORDER BY 1



// Awards-received vs imdb votes 
WITH
subquery_deduplication AS (SELECT DENSE_RANK() OVER (ORDER BY title, series_or_movie, director, release_date) AS netflix_id,*
FROM hive.myschema.netflix)
,subquery_imdb_votes_count AS (SELECT netflix_id,
                                     CAST((CASE WHEN imdb_votes = '' THEN '0' ELSE SPLIT_PART(imdb_votes,'.', 1) END) AS INT) AS imdb_votes,
                                    CAST((CASE WHEN awards_received = '' THEN '0' ELSE SPLIT_PART(awards_received,'.', 1) END) AS INT) AS awards_received
FROM subquery_deduplication)
, subquery_group_by_netflix_id AS (SELECT netflix_id, avg(imdb_votes) AS avg_imdb_votes, avg(awards_received) AS awards_received FROM subquery_imdb_votes_count GROUP BY 1)
SELECT * FROM subquery_group_by_netflix_id 



// Awards-nominated vs imdb votes
WITH
subquery_deduplication AS (SELECT DENSE_RANK() OVER (ORDER BY title, series_or_movie, director, release_date) AS netflix_id,*
FROM hive.myschema.netflix)
,subquery_imdb_votes_count AS (SELECT netflix_id,
                                     CAST((CASE WHEN imdb_votes = '' THEN '0' ELSE SPLIT_PART(imdb_votes,'.', 1) END) AS INT) AS imdb_votes,
                                    CAST((CASE WHEN awards_nominated_for = '' THEN '0' ELSE SPLIT_PART(awards_nominated_for,'.', 1) END) AS INT) AS awards_nominated_for
FROM subquery_deduplication)
, subquery_group_by_netflix_id AS (SELECT netflix_id, avg(imdb_votes) AS avg_imdb_votes, avg(awards_nominated_for) AS awards_nominated_for FROM subquery_imdb_votes_count GROUP BY 1)
SELECT * FROM subquery_group_by_netflix_id 
