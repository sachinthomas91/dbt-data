with order_lines as (
    select * from {{ ref('fact_order_lines') }}
)

, orders as (
    select * from {{ ref('fact_orders') }}
)

, aggregated_daily_sales as (
    select
         lin.seller_id
        ,min(date(ord.order_purchase_datetime)) as first_sale_date
        ,max(date(ord.order_purchase_datetime)) as last_sale_date
        ,date_diff(max(date(ord.order_purchase_datetime)), current_date(), DAY) as days_since_last_sale
        ,round(sum(ord.order_total), 2) as life_time_seller_sales_value
        ,round(avg(ord.order_total), 2) as avg_sale_value
        ,count(distinct ord.order_id) as total_order_count
        ,countif(ord.order_status = 'Canceled') AS canceled_order_count
        ,countif(ord.order_status = 'Unavailable') AS unavaialble_order_count
        ,round(sum(if(ord.order_status = 'Canceled', payment_total, 0)), 2) as lost_revenue_canceled
        ,round(sum(if(ord.order_status = 'Unavailable', payment_total, 0)), 2) as lost_revenue_unavailable
        ,round(avg(ord.review_score), 2) as avg_review_score        
        ,round(count(distinct ord.order_id) / nullif(date_diff(current_date(), min(date(ord.order_purchase_datetime)), DAY), 0) / 30, 2) as avg_monthly_orders
        ,round(sum(ord.order_total) / nullif(date_diff(current_date(), min(date(ord.order_purchase_datetime)), DAY), 0) / 30, 2) as avg_monthly_revenue
        ,round((countif(ord.order_status = 'Canceled') + countif(ord.order_status = 'Unavailable')) / nullif(count(distinct ord.order_id), 0) * 100, 2) as order_problem_rate
        ,case 
            when date_diff(max(date(ord.order_purchase_datetime)), current_date(), DAY) <= 30 then 'Active'
            when date_diff(max(date(ord.order_purchase_datetime)), current_date(), DAY) <= 90 then 'At Risk'
            when date_diff(max(date(ord.order_purchase_datetime)), current_date(), DAY) <= 180 then 'Churning'
            else 'Churned'
        end as seller_status
    from 
        orders ord
        left join order_lines lin
            on ord.order_id = lin.order_id
    group by 
        all
)

select
    *
from
    aggregated_daily_sales