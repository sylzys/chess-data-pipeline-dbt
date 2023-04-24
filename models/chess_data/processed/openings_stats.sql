WITH data AS (
    SELECT
        opening,
        time_class,
        white_rating,
        black_rating,
        white_result
    FROM {{ref("processed_games")}}
)

SELECT
    opening,
    AVG(white_rating) AS avg_opener_rating,
    AVG(black_rating) AS avg_opponent_rating,
    SUM(CASE WHEN white_result = 'win' THEN 1 ELSE 0 END) AS opening_won,
    COUNT(white_result) AS amount_games_played,
    (opening_won / amount_games_played) * 100AS opening_win_rate
FROM data GROUP BY opening
