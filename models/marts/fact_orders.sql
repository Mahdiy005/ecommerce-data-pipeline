WITH orders AS (

    SELECT *
    FROM {{ ref('stg_orders') }}

),

customers AS (

    SELECT
        customer_key,
        customer_id
    FROM {{ ref('dim_customers') }}

),

final AS (

    SELECT
        o.order_id,
        c.customer_key,

        TO_NUMBER(
            TO_CHAR(o.order_date, 'YYYYMMDD')
        ) AS order_date_key,

        o.order_status,
        o.payment_method,
        o.shipping_city,
        o.currency,

        o.shipping_fee,
        o.discount_amount,
        o.order_total,

        1 AS order_count

    FROM orders AS o

    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id

)

SELECT *
FROM final