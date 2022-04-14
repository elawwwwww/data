CREATE EXTERNAL TABLE IF NOT EXISTS myschema.netflix
(
title string,
genre string,
tags string,
languages string,
series_or_movie string,
hidden_gem_score string,
country_availability string,
runtime string,
director string,
writer string,
actors string,
view_rating string,
imdb_score string,
rotten_tomatoes_score string,
metacritic_score string,
awards_received string,
awards_nominated_for string,
boxoffice string,
release_date string,
netflix_release_date string,
production_house string,
netflix_link string,
imdb_link string,
summary string,
imdb_votes string,
image string,
poster string,
tmdb_trailer string,
trailer_site string
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\1'
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1')
;
