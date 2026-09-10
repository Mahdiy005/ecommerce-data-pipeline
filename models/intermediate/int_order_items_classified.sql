WITH order_items AS (

    SELECT *
    FROM {{ ref('stg_order_items') }}

),

classified AS (

    SELECT
        oi.*,

        ARRAY_CONSTRUCT_COMPACT(
            IFF(
                oi.order_id IS NULL,
                'ORDER_ID_IS_NULL',
                NULL
            ),

            IFF(
                oi.order_id IS NOT NULL
                AND o.order_id IS NULL,
                'ORDER_NOT_FOUND',
                NULL
            ),

            IFF(
                oi.product_id IS NULL,
                'PRODUCT_ID_IS_NULL',
                NULL
            ),

            IFF(
                oi.product_id IS NOT NULL
                AND p.product_id IS NULL,
                'PRODUCT_NOT_FOUND',
                NULL
            )
        ) AS invalid_reasons_array

    FROM order_items AS oi

    LEFT JOIN {{ ref('stg_orders') }} AS o
        ON oi.order_id = o.order_id

    LEFT JOIN {{ ref('stg_products') }} AS p
        ON oi.product_id = p.product_id

),

final AS (

    SELECT
        * EXCLUDE (invalid_reasons_array),

        CASE
            WHEN ARRAY_SIZE(invalid_reasons_array) = 0 THEN 'VALID'
            ELSE 'INVALID'
        END AS record_status,

        NULLIF(
            ARRAY_TO_STRING(invalid_reasons_array, ' | '),
            ''
        ) AS invalid_reason

    FROM classified

)

SELECT *
FROM final