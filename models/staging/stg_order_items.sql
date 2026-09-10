WITH source AS (

    SELECT *
    FROM {{ source('finance_raw', 'order_items') }}

),

cleaned AS (

    SELECT

        /* IDs */
        NULLIF(UPPER(TRIM(order_item_id)), '') AS original_order_item_id,
        NULLIF(UPPER(TRIM(order_id)), '') AS order_id,
        NULLIF(UPPER(TRIM(product_id)), '') AS product_id,

        /* Numeric values */
        TRY_TO_NUMBER(
            NULLIF(TRIM(TO_VARCHAR(quantity)), '')
        ) AS quantity,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(TO_VARCHAR(unit_price)), ''),
            12,
            2
        ) AS unit_price,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(TO_VARCHAR(discount_pct)), ''),
            5,
            2
        ) AS discount_pct,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(TO_VARCHAR(line_total)), ''),
            12,
            2
        ) AS line_total,
        CASE
    WHEN NULLIF(TRIM(warehouse_code), '') IS NULL
        THEN NULL

    -- Already standardized: WH-CAI-01
    WHEN REGEXP_LIKE(
        UPPER(TRIM(warehouse_code)),
        '^WH-[A-Z]{3}-[0-9]{2}$'
    )
        THEN UPPER(TRIM(warehouse_code))

    -- Unformatted value: CAI01
    WHEN REGEXP_LIKE(
        UPPER(TRIM(warehouse_code)),
        '^[A-Z]{3}[0-9]{2}$'
    )
        THEN
            'WH-'
            || SUBSTR(UPPER(TRIM(warehouse_code)), 1, 3)
            || '-'
            || SUBSTR(UPPER(TRIM(warehouse_code)), 4, 2)

    ELSE NULL
END AS warehouse_code

    FROM source

),

generated_ids AS (

    SELECT

        COALESCE(
            original_order_item_id,

            CONCAT(
                'GENERATED_',
                {{ dbt_utils.generate_surrogate_key([
                    'order_id',
                    'product_id',
                    'quantity',
                    'unit_price',
                    'discount_pct',
                    'line_total',
                    'warehouse_code'
                ]) }}
            )
        ) AS order_item_id,

        order_id,
        product_id,
        quantity,
        unit_price,
        discount_pct,
        line_total,
        warehouse_code

    FROM cleaned

)

SELECT *
FROM generated_ids