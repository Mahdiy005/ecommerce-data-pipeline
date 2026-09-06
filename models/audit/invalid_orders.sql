SELECT
    *,
    CURRENT_TIMESTAMP() AS audited_at
FROM {{ ref('int_orders_classified') }}
WHERE rejection_reason IS NOT NULL