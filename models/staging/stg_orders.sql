SELECT
    order_id,
    customer_id,
    order_date,
    order_status,
    payment_method,
    shipping_city,
    shipping_fee,
    discount_amount,
    order_total,
    currency
FROM {{ ref('int_orders_classified') }}
WHERE rejection_reason IS NULL