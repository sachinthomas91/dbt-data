with orders as (
  select * from {{ ref('stg_orders')}}
)

,order_lines as (
  select * from {{ ref('stg_order_items')}}
)

,order_payments as (
  select * from {{ ref('stg_order_payments')}}
)

,reviews as (
  select * from {{ ref('stg_reviews')}}
)

,dim_customers as (
  select * from {{ ref('dim_customers')}}
)

,aggregate_order_lines as (
  select 
     order_id
    ,count(order_item_id) as order_item_count
    ,round(sum(item_price), 2) as order_item_price_total
    ,round(sum(item_freight_value), 2) as order_freight_total
    ,round((sum(item_price) + sum(item_freight_value)), 2) as order_total
  from
    order_lines
  group by 
    order_id
)

,aggregate_order_payments as (
  select 
     order_id
    ,count(distinct payment_type_sequence) as payment_count
    ,count(distinct payment_type) as payment_method_type_count
    ,max(payment_installment_count) as payment_installment_count
    ,round(sum(payment_value), 2) as payment_total
  from
    order_payments
  group by 
    order_id
)

,aggregate_reviews as (
  select 
     order_id
    ,review_score
  from
    reviews
)

select
   ord.order_id
  ,cust.customer_id
  ,ord.order_status
  ,coalesce(lin.order_item_count, 0) as order_item_count
  ,coalesce(lin.order_item_price_total, 0) as order_item_price_total
  ,coalesce(lin.order_freight_total, 0) as order_freight_total
  ,coalesce(lin.order_total, 0) as order_total
  ,coalesce(pay.payment_count, 0) as payment_count
  ,coalesce(pay.payment_method_type_count, 0) as payment_method_type_count
  ,coalesce(pay.payment_installment_count, 0) as payment_installment_count
  ,coalesce(pay.payment_total, 0) as payment_total
  ,rev.review_score
  ,timestamp_diff(ord.order_approved_datetime, ord.order_purchase_datetime, hour) as time_to_approval_hours
  ,timestamp_diff(ord.order_delivered_carrier_datetime, ord.order_purchase_datetime, hour) as time_to_ship_hours 
  ,timestamp_diff(ord.order_delivered_customer_datetime, ord.order_purchase_datetime, hour) as time_to_deliver_hours 
  ,timestamp_diff(ord.order_delivered_customer_datetime, ord.order_estimated_delivery_datetime, hour) as delivery_estimation_slip_hours 
  ,ord.order_purchase_datetime
  ,ord.order_approved_datetime
  ,ord.order_delivered_carrier_datetime
  ,ord.order_delivered_customer_datetime
  ,ord.order_estimated_delivery_datetime
from 
  orders ord
  left join aggregate_order_lines lin
    on ord.order_id=lin.order_id
  left join aggregate_order_payments pay
    on ord.order_id=pay.order_id
  left join aggregate_reviews rev
    on ord.order_id=rev.order_id
  left join dim_customers cust
    on ord.order_customer_id=cust.order_customer_id
