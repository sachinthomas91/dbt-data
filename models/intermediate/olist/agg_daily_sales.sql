with fact_orders as (
    select * from {{ ref('fact_orders') }}
)

, aggregated_daily_sales as (
    select
        date(order_purchase_datetime) as order_date
        ,count(order_id) as total_order_count
        ,countif(order_status = 'Canceled') AS canceled_order_count
        ,countif(order_status = 'Unavailable') AS unavaialble_order_count
        ,round(sum(order_total), 2) as total_order_value
        ,round(sum(payment_total), 2) as total_paid
        ,round(sum(if(order_status = 'Canceled', payment_total, 0)), 2) as lost_revenue_canceled
        ,round(sum(if(order_status = 'Unavailable', payment_total, 0)), 2) as lost_revenue_unavailable
        ,round(avg(review_score), 2) as avg_review_score
    from
        fact_orders
    group by 
        all
)

select
    *
from
    aggregated_daily_sales