with fact_orders as (
    select * from {{ ref('fact_orders') }}
)

, aggregated_daily_sales as (    select
        customer_id
        ,min(date(order_purchase_datetime)) as first_purchase_date
        ,max(date(order_purchase_datetime)) as last_purchase_date
        ,date_diff(max(date(order_purchase_datetime)), current_date(), DAY) as days_since_last_purchase
        ,date_diff(max(date(order_purchase_datetime)), min(date(order_purchase_datetime)), DAY) as customer_lifetime_days
        ,round(sum(order_total), 2) as life_time_customer_value
        ,round(avg(order_total), 2) as avg_order_value
        ,count(order_id) as total_order_count
        ,countif(order_status = 'Canceled') AS canceled_order_count
        ,countif(order_status = 'Unavailable') AS unavaialble_order_count
        ,round(sum(if(order_status = 'Canceled', payment_total, 0)), 2) as lost_revenue_canceled
        ,round(sum(if(order_status = 'Unavailable', payment_total, 0)), 2) as lost_revenue_unavailable
        ,round(avg(review_score), 2) as avg_review_score
        -- Derived Metrics
        ,round(count(order_id) / nullif(date_diff(max(date(order_purchase_datetime)), min(date(order_purchase_datetime)), DAY), 0) * 30, 2) as avg_monthly_orders
        ,round(sum(order_total) / nullif(date_diff(max(date(order_purchase_datetime)), min(date(order_purchase_datetime)), DAY), 0) * 30, 2) as avg_monthly_spend
        ,round((countif(order_status in ('Canceled', 'Unavailable')) / nullif(count(order_id), 0)) * 100, 2) as problem_order_rate
        ,round(stddev(order_total), 2) as order_value_stddev
        ,round((sum(if(review_score >= 4, 1, 0)) / nullif(count(review_score), 0)) * 100, 2) as positive_review_rate
        -- Customer Status
        ,case 
            when date_diff(max(date(order_purchase_datetime)), current_date(), DAY) <= 30 then 'Active'
            when date_diff(max(date(order_purchase_datetime)), current_date(), DAY) <= 90 then 'At Risk'
            when date_diff(max(date(order_purchase_datetime)), current_date(), DAY) <= 180 then 'Churning'
            else 'Churned'
        end as customer_status
        -- Customer Value Tier based on avg monthly spend
        ,case 
            when round(sum(order_total) / nullif(date_diff(max(date(order_purchase_datetime)), min(date(order_purchase_datetime)), DAY), 0) * 30, 2) >= 1000 then 'High Value'
            when round(sum(order_total) / nullif(date_diff(max(date(order_purchase_datetime)), min(date(order_purchase_datetime)), DAY), 0) * 30, 2) >= 500 then 'Medium Value'
            else 'Low Value'
        end as customer_value_tier
    from
        fact_orders
    group by 
        all
)

select
    *
from
    aggregated_daily_sales