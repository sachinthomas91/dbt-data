with source as (
    select * from {{ ref('seed_olist_customers') }}

),

renamed as (
    select
        customer_unique_id as customer_id,
        customer_id as order_customer_id,
        customer_zip_code_prefix as customer_zip_code,
        INITCAP(customer_city) as customer_city,
        UPPER(customer_state) as customer_state
    from 
        source
    where
        customer_unique_id is not null
        and customer_id is not null
)

select * from renamed