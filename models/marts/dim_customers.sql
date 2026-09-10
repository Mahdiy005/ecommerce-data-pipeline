WITH customers AS (

    SELECT *
    FROM {{ ref('stg_customers') }}

),

final AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'customer_id'
        ]) }} AS customer_key,

        customer_id,
        full_name,
        email,
        phone,
        city,
        governorate,
        signup_date,
        birth_date,
        gender,
        loyalty_points,
        is_active

    FROM customers

)

SELECT *
FROM final