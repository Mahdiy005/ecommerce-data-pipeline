WITH source AS (

    SELECT *
    FROM {{ source('finance_raw', 'products') }}

),

cleaned AS (

    SELECT
        /* IDs */
        NULLIF(UPPER(TRIM(product_id)), '') AS product_id,
        NULLIF(UPPER(TRIM(supplier_id)), '') AS supplier_id,

        /* Text */
        INITCAP(
            NULLIF(TRIM(product_name), '')
        ) AS product_name,

        INITCAP(
            NULLIF(TRIM(category), '')
        ) AS category,

        INITCAP(
            NULLIF(TRIM(brand), '')
        ) AS brand,

        /* Numeric values */
        abs(TRY_TO_DECIMAL(
            NULLIF(TRIM(TO_VARCHAR(unit_price)), ''),
            12,
            2
        )) AS unit_price,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(TO_VARCHAR(cost_price)), ''),
            12,
            2
        ) AS cost_price,

        abs(TRY_TO_NUMBER(
            NULLIF(TRIM(TO_VARCHAR(stock_quantity)), '')
        )) AS stock_quantity,

        /* Date */
        COALESCE(
            TRY_TO_DATE(NULLIF(TRIM(created_at), ''), 'YYYY-MM-DD'),
            TRY_TO_DATE(NULLIF(TRIM(created_at), ''), 'DD/MM/YYYY'),
            TRY_TO_DATE(NULLIF(TRIM(created_at), ''), 'MM-DD-YYYY')
        ) AS created_at,

        /* Status */
        CASE
            WHEN LOWER(TRIM(status)) IN (
                'active',
                'available',
                'enabled'
            )
                THEN 'Active'

            WHEN LOWER(TRIM(status)) IN (
                'inactive',
                'unavailable',
                'disabled'
            )
                THEN 'Inactive'

            WHEN LOWER(TRIM(status)) IN (
                'discontinued',
                'discontinue'
            )
                THEN 'Discontinued'

            ELSE NULL
        END AS status

    FROM source

),

deduplicated AS (

    SELECT *
    FROM cleaned

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY product_id
        ORDER BY created_at DESC NULLS LAST
    ) = 1

)

SELECT *
FROM deduplicated