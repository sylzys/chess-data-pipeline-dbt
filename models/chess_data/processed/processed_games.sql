WITH data AS (
    SELECT
        end_time,
        time_class,
        opening,
        parse_json("WHITE") AS white_json,
        parse_json("BLACK") AS black_json,
        uuid
    FROM {{ref("staging_data")}}
),
players_info AS (
    SELECT
        time_class,
        opening,
        white_json:uuid::string AS white,
        white_json:rating::integer AS white_rating,
        white_json:result::string AS white_result,
        black_json:rating::integer AS black_rating
    FROM data
)

SELECT
    *
FROM players_info
