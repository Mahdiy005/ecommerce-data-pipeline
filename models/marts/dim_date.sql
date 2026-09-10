WITH date_spine AS (

    {{
        dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2020-01-01' as date)",
            end_date="cast('2031-01-01' as date)"
        )
    }}

),

final AS (

    SELECT
        TO_NUMBER(TO_CHAR(date_day, 'YYYYMMDD')) AS date_key,
        CAST(date_day AS DATE) AS full_date,
        DAY(date_day) AS day_number,
        DAYNAME(date_day) AS day_name,
        WEEKOFYEAR(date_day) AS week_number,
        MONTH(date_day) AS month_number,
        MONTHNAME(date_day) AS month_name,
        QUARTER(date_day) AS quarter_number,
        YEAR(date_day) AS year_number,
        DAYOFWEEKISO(date_day) IN (5, 6) AS is_weekend

    FROM date_spine

)

SELECT *
FROM final