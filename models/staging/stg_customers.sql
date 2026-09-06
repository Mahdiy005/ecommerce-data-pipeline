WITH source AS (

    SELECT *
    FROM {{ source('finance_raw', 'customers') }}

),

cleaned AS (

    SELECT
        /* IDs */
        NULLIF(UPPER(TRIM(customer_id)), '') AS customer_id,

        /* Text columns */
        NULLIF(
            INITCAP(
                REGEXP_REPLACE(TRIM(full_name), '[[:space:]]+', ' ')
            ),
            ''
        ) AS full_name,

        /* Email */
        CASE
            WHEN REGEXP_LIKE(
                TRIM(email),
                '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}$'
            )
            THEN LOWER(TRIM(email))
            WHEN Email = 'invalid-email' THEN NULL
            ELSE NULL
        END AS email,

        /* Keep + and numbers only */
        NULLIF(
            REGEXP_REPLACE(TRIM(phone), '[^0-9+]', ''),
            ''
        ) AS phone,

        /* Locations */
        NULLIF(
            INITCAP(REGEXP_REPLACE(TRIM(city), '[[:space:]]+', ' ')),
            ''
        ) AS city,

        NULLIF(
            INITCAP(
                REGEXP_REPLACE(TRIM(governorate), '[[:space:]]+', ' ')
            ),
            ''
        ) AS governorate,

        /* Dates */
        CASE
            /* Missing values */
            WHEN signup_date IS NULL
            OR TRIM(signup_date) = ''
            OR LOWER(TRIM(signup_date)) IN (
                'not_available',
                'n/a',
                'na',
                'null',
                'unknown'
            )
                THEN NULL

            /* Example: 31/01/2025 = DD/MM/YYYY */
            WHEN REGEXP_LIKE(
                TRIM(signup_date),
                '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            )
                THEN TRY_TO_DATE(
                    TRIM(signup_date),
                    'DD/MM/YYYY'
                )

            /* Example: 12-21-2024 = MM-DD-YYYY */
            WHEN REGEXP_LIKE(
                TRIM(signup_date),
                '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
            )
                THEN TRY_TO_DATE(
                    TRIM(signup_date),
                    'MM-DD-YYYY'
                )

            /* Optional ISO format: 2025-01-31 */
            WHEN REGEXP_LIKE(
                TRIM(signup_date),
                '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            )
                THEN TRY_TO_DATE(
                    TRIM(signup_date),
                    'YYYY-MM-DD'
                )
            ELSE NULL
        END AS signup_date,
        COALESCE(
            TRY_TO_DATE(TRIM(birth_date), 'DD/MM/YYYY'),
            TRY_TO_DATE(TRIM(birth_date), 'MM-DD-YYYY'),
            TRY_TO_DATE(TRIM(birth_date), 'YYYY-MM-DD')
        ) AS birth_date,
        -- TRY_TO_DATE(TRIM(birth_date)) AS birth_date,
        -- TRY_TO_DATE(TRIM(signup_date)) AS signup_date,

        /* Gender normalization */
        CASE
            WHEN LOWER(TRIM(gender)) IN ('m', 'M', 'male', 'Male')
                THEN 'Male'

            WHEN LOWER(TRIM(gender)) IN ('f', 'F', 'female', 'Female')
                THEN 'Female'

            WHEN gender IS NULL OR TRIM(gender) = ''
                THEN 'Unknown'

            ELSE 'Unknown'
        END AS gender,

        /* Numeric values */
        CASE
            WHEN TRY_TO_NUMBER(TRIM(loyalty_points)) >= 0
                THEN TRY_TO_NUMBER(TRIM(loyalty_points))
            ELSE 0
        END AS loyalty_points,

        /* Boolean normalization */
        CASE
            WHEN LOWER(TRIM(is_active)) IN (
                'true', '1', 'yes', 'y', 'active'
            )
                THEN TRUE

            WHEN LOWER(TRIM(is_active)) IN (
                'false', '0', 'no', 'n', 'inactive'
            )
                THEN FALSE

            ELSE NULL
        END AS is_active

    FROM source

),

deduplicated AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY signup_date DESC NULLS LAST
        ) AS row_num
    FROM cleaned

)

SELECT
    customer_id,
    full_name,
    email,
    phone,
    city,
    governorate,
    signup_date,
    birth_date,
    gender,
    loyalty_points,
    is_active
FROM deduplicated
WHERE row_num = 1
  AND customer_id IS NOT NULL