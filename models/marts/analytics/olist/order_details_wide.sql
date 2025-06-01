with order_lines as (
    select * from {{ ref('fact_order_lines') }}
)

, orders as (
    select * from {{ ref('fact_orders') }}
)

, customers as (
    select * from {{ ref('dim_customers') }}
)

, sellers as (
    select * from {{ ref('dim_sellers') }}
)

select
    -- Order Line Details
    lin.order_id,
    lin.order_item_id,
    lin.shipping_limit_datetime,
    lin.item_price,
    lin.item_freight_value,
    
    -- Order Details
    ord.order_status,
    ord.order_item_count,
    ord.order_item_price_total,
    ord.order_freight_total,
    ord.order_total,
    ord.payment_count,
    ord.payment_method_type_count,
    ord.payment_installment_count,
    ord.payment_total,
    ord.review_score,
    ord.time_to_approval_hours,
    ord.time_to_ship_hours,
    ord.time_to_deliver_hours,
    ord.delivery_estimation_slip_hours,
    ord.order_purchase_datetime,
    ord.order_approved_datetime,
    ord.order_delivered_carrier_datetime,
    ord.order_delivered_customer_datetime,
    ord.order_estimated_delivery_datetime,
    
    -- Customer Details
    cus.customer_id,
    cus.customer_city,
    cus.customer_state,
    cus.customer_zip_code,
    
    -- Seller Details
    sel.seller_id,
    sel.seller_city,
    sel.seller_state,
    sel.seller_zip_code
from 
    order_lines lin
    left join orders ord
        on lin.order_id = ord.order_id
    left join customers cus
        on lin.customer_id = cus.customer_id
    left join sellers sel
        on lin.seller_id = sel.seller_id

