with source as (
    select * from {{ ref('seed_olist_orders') }}
),

renamed as (
    select
        order_id,
        customer_id as order_customer_id,
        INITCAP(order_status) as order_status,
        order_purchase_timestamp as order_purchase_datetime,
        order_approved_at as order_approved_datetime,
        order_delivered_carrier_date as order_delivered_carrier_datetime,
        order_delivered_customer_date as order_delivered_customer_datetime,
        order_estimated_delivery_date as order_estimated_delivery_datetime
    from 
        source
    where 
        order_id is not null 
        and customer_id is not null
)

select * from renamed
