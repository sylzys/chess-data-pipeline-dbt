WITH data AS (
    SELECT
        end_time,
        time_class,
        parse_json("WHITE") AS white_json,
        parse_json("BLACK") AS black_json,
        uuid
    FROM {{ref("staging_data")}}
),
players_from_white AS (
    SELECT
        end_time,
        time_class,
        white_json:uuid::string AS player_id,
        white_json:rating::integer AS rating,
        white_json:username::string AS username,
        white_json:result::string AS white_result
    FROM data
),
players_from_black AS (
    SELECT
        end_time,
        time_class,
        black_json:uuid::string AS player_id,
        black_json:rating::integer AS rating,
        black_json:username::string AS username,
        black_json:result::string AS black_result
    FROM data
),
all_players AS (
    SELECT
        end_time,
        player_id,
        time_class,
        rating,
        username,
        white_result,
        NULL AS black_result
    FROM players_from_white
    UNION ALL
    SELECT
        end_time,
        time_class,
        player_id,
        rating,
        username,
        NULL AS white_result,
        black_result
    FROM players_from_black
)
  SELECT
    all_players.username,
    all_players.player_id,
    SUM(CASE WHEN all_players.white_result = 'win' THEN 1 ELSE 0 END) AS amount_won_as_white,
    SUM(CASE WHEN all_players.black_result = 'win' THEN 1 ELSE 0 END) AS amount_won_as_black,
    SUM(CASE WHEN all_players.white_result = 'agreed' THEN 1 ELSE 0 END) AS amount_draw_as_white,
    SUM(CASE WHEN all_players.black_result = 'agreed' THEN 1 ELSE 0 END) AS amount_draw_as_black,
    SUM(CASE WHEN all_players.white_result = 'timeout' THEN 1 ELSE 0 END) AS amount_timeout_as_white,
    SUM(CASE WHEN all_players.white_result = 'timeout' THEN 1 ELSE 0 END) AS amount_timeout_as_black,
    SUM(CASE WHEN all_players.white_result = 'checkmated' THEN 1 ELSE 0 END) AS amount_checkmated_as_white,
    SUM(CASE WHEN all_players.white_result = 'checkmated' THEN 1 ELSE 0 END) AS amount_checkmated_as_black,
    SUM(CASE WHEN all_players.white_result = 'abandoned' THEN 1 ELSE 0 END) AS amount_abandoned_as_white,
    SUM(CASE WHEN all_players.white_result = 'abandoned' THEN 1 ELSE 0 END) AS amount_abandoned_as_black,
    SUM(CASE WHEN all_players.white_result = 'resigned' THEN 1 ELSE 0 END) AS amount_resigned_as_white,
    SUM(CASE WHEN all_players.black_result = 'resigned' THEN 1 ELSE 0 END) AS amount_resigned_as_black,
    SUM(CASE WHEN all_players.white_result != null THEN 1 ELSE 0 END) AS games_played_as_white,
    SUM(CASE WHEN all_players.black_result != null THEN 1 ELSE 0 END) AS games_played_as_black,
    SUM(CASE WHEN time_class = 'rapid' THEN 1 ELSE 0 END) AS amount_rapid_games_played,
    SUM(CASE WHEN time_class = 'blitz' THEN 1 ELSE 0 END) AS amount_blitz_games_played,
    SUM(CASE WHEN time_class = 'bullet' THEN 1 ELSE 0 END) AS amount_bullet_games_played,
    COUNT(end_time) as games_played
FROM
    all_players
GROUP BY
    all_players.username, all_players.player_id
