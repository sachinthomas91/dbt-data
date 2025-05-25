-- stg_order_items.sql
with source as (
    select * from {{ ref('seed_olist_order_items') }}
),

renamed as (
    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date as shipping_limit_datetime,
        price as item_price,
        freight_value as item_freight_value
    from 
        source
    where 
        order_id is not null 
        and product_id is not null
)

select * from renamed