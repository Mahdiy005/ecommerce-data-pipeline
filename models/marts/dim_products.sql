WITH products AS (

    SELECT *
    FROM {{ ref('stg_products') }}

),

final AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'product_id'
        ]) }} AS product_key,

        product_id,
        product_name,
        category,
        brand,
        unit_price AS current_unit_price,
        cost_price AS current_cost_price,
        stock_quantity,
        supplier_id,
        created_at,
        status AS product_status

    FROM products

)

SELECT *
FROM final