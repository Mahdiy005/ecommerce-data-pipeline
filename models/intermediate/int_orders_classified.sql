WITH cleaned AS (

    SELECT
        /* IDs */
        NULLIF(UPPER(TRIM(order_id)), '') AS order_id,
        NULLIF(UPPER(TRIM(customer_id)), '') AS customer_id,

        /* Date */
         CASE
            /* Missing values */
            WHEN order_date IS NULL
            OR TRIM(order_date) = ''
            OR LOWER(TRIM(order_date)) IN (
                'not_available',
                'n/a',
                'na',
                'null',
                'unknown'
            )
                THEN NULL

            /* Example: 31/01/2025 = DD/MM/YYYY */
            WHEN REGEXP_LIKE(
                TRIM(order_date),
                '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            )
                THEN TRY_TO_DATE(
                    TRIM(order_date),
                    'DD/MM/YYYY'
                )

            /* Example: 12-21-2024 = MM-DD-YYYY */
            WHEN REGEXP_LIKE(
                TRIM(order_date),
                '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
            )
                THEN TRY_TO_DATE(
                    TRIM(order_date),
                    'MM-DD-YYYY'
                )

            /* Optional ISO format: 2025-01-31 */
            WHEN REGEXP_LIKE(
                TRIM(order_date),
                '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            )
                THEN TRY_TO_DATE(
                    TRIM(order_date),
                    'YYYY-MM-DD'
                )
            ELSE NULL
        END AS order_date,

        /* Order status */
        CASE
            WHEN LOWER(TRIM(order_status)) IN ('pending', 'pen')
                THEN 'Pending'

            WHEN LOWER(TRIM(order_status)) IN (
                'processing',
                'in progress',
                'in_progress'
            )
                THEN 'Processing'

            WHEN LOWER(TRIM(order_status)) IN ('shipped', 'shipping')
                THEN 'Shipped'

            WHEN LOWER(TRIM(order_status)) IN (
                'delivered',
                'completed',
                'complete'
            )
                THEN 'Delivered'

            WHEN LOWER(TRIM(order_status)) IN (
                'cancelled',
                'canceled',
                'cancel'
            )
                THEN 'Cancelled'

            ELSE NULL
        END AS order_status,

        /* Payment method */
        CASE
            WHEN LOWER(TRIM(payment_method)) IN (
                'card',
                'credit card',
                'credit_card',
                'debit card',
                'debit_card'
            )
                THEN 'Card'

            WHEN LOWER(TRIM(payment_method)) IN (
                'cash',
                'cash on delivery',
                'cod'
            )
                THEN 'Cash'

            WHEN LOWER(TRIM(payment_method)) IN (
                'bank transfer',
                'bank_transfer',
                'transfer'
            )
                THEN 'Bank Transfer'

            WHEN LOWER(TRIM(payment_method)) IN (
                'wallet',
                'e-wallet',
                'ewallet'
            )
                THEN 'Wallet'

            ELSE NULL
        END AS payment_method,

        /* Location */
        INITCAP(NULLIF(TRIM(shipping_city), '')) AS shipping_city,

        /* Numeric columns */
        ABS(
            TRY_TO_DECIMAL(
                NULLIF(TRIM(TO_VARCHAR(shipping_fee)), ''),
                12,
                2
            )
        ) AS shipping_fee,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(TO_VARCHAR(discount_amount)), ''),
            12,
            2
        ) AS discount_amount,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(TO_VARCHAR(order_total)), ''),
            12,
            2
        ) AS order_total,

        /* Currency */
        CASE
            WHEN UPPER(TRIM(currency)) IN ('EGP', 'LE', 'L.E')
                THEN 'EGP'

            WHEN UPPER(TRIM(currency)) IN ('SAR', 'SR')
                THEN 'SAR'

            WHEN UPPER(TRIM(currency)) IN ('USD', '$')
                THEN 'USD'

            ELSE NULL
        END AS currency

    FROM {{ source('finance_raw', 'orders') }}

),

classified AS (

    SELECT
        o.*,

        CASE
            -- WHEN order_id IS NULL
            --     THEN 'MISSING_ORDER_ID'

            -- WHEN customer_id IS NULL
            --     THEN 'MISSING_CUSTOMER_ID'

            -- WHEN order_date IS NULL
            --     THEN 'INVALID_ORDER_DATE'

            -- WHEN order_total IS NULL
            --     THEN 'INVALID_ORDER_TOTAL'

            -- WHEN order_total <= 0
            --     THEN 'NON_POSITIVE_ORDER_TOTAL'

            -- WHEN shipping_fee IS NULL OR shipping_fee < 0
            --     THEN 'INVALID_SHIPPING_FEE'

            -- WHEN discount_amount IS NULL OR discount_amount < 0
            --     THEN 'INVALID_DISCOUNT_AMOUNT'

            WHEN NOT EXISTS (
                SELECT 1
                FROM {{ ref('stg_customers') }} c
                WHERE c.customer_id = o.customer_id
            )
                THEN 'CUSTOMER_NOT_FOUND'

            ELSE NULL
        END AS rejection_reason

    FROM cleaned o

)

SELECT *
FROM classified