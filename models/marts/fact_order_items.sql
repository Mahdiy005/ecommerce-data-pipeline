WITH order_items AS (

    SELECT *
    FROM {{ ref('int_valid_order_items') }}

),

products AS (

    SELECT
        product_key,
        product_id
    FROM {{ ref('dim_products') }}

),

orders AS (

    SELECT
        order_id,
        customer_key,
        order_date_key
    FROM {{ ref('fact_orders') }}

),

final AS (

    SELECT
        oi.order_item_id,
        oi.order_id,

        o.customer_key,
        o.order_date_key,
        p.product_key,

        oi.warehouse_code,
        oi.quantity,
        oi.unit_price,
        oi.discount_pct,
        oi.line_total,

        oi.quantity * oi.unit_price AS gross_line_amount,

        (oi.quantity * oi.unit_price) - oi.line_total
            AS line_discount_amount,

        1 AS line_count

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

)

SELECT *
FROM final