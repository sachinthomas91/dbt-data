with order_lines as (
  select * from {{ ref('stg_order_items')}}
)

,orders as (
  select * from {{ ref('stg_orders')}}
)

,dim_products as (
  select * from {{ ref('dim_products')}}
)

,dim_customers as (
  select * from {{ ref('dim_customers')}}
)

,dim_sellers as (
  select * from {{ ref('dim_sellers')}}
)

,reviews as (
  select * from {{ ref('stg_reviews')}}
)


select
   lin.order_id
  ,lin.order_item_id
  ,cust.customer_id
  ,ord.order_status
  ,lin.product_id
  ,lin.seller_id
  ,lin.shipping_limit_datetime
  ,lin.item_price
  ,lin.item_freight_value
  ,rev.review_score
from 
  order_lines lin
  left join orders ord
    on lin.order_id=ord.order_id
  left join dim_customers cust
    on ord.order_customer_id=cust.order_customer_id
  left join dim_products prod
    on lin.product_id=prod.product_id
  left join dim_sellers sel
    on lin.seller_id=sel.seller_id
  left join reviews rev
    on ord.order_id=rev.order_id
