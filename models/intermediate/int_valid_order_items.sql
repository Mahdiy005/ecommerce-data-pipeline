WITH classified_order_items AS (

    SELECT *
    FROM {{ ref('int_order_items_classified') }}

),

valid_order_items AS (

    SELECT
        order_item_id,
        order_id,
        product_id,
        quantity,
        unit_price,
        discount_pct,
        line_total,
        warehouse_code

    FROM classified_order_items

    WHERE record_status = 'VALID'

)

SELECT *
FROM valid_order_items