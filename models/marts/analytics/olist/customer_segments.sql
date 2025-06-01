{{ config(
    materialized='table',
) }}

with customer_performance as (
    -- Reference the aggregated customer performance data
    select
        customer_id,
        total_order_count,
        life_time_customer_value,
        last_purchase_date,
        days_since_last_purchase -- This is Recency
    from 
        {{ ref('agg_customer_performance') }}
),

rfm_scores as (
    -- Calculate RFM scores (e.g., 1-5 for each metric)
    -- Higher score typically means better performance for that metric.
    -- Adjust the NTILE (number of groups) based on your desired granularity.
    -- For simplicity, we'll use 5 groups (quintiles).

    select
        customer_id,
        -- Recency Score: Lower days_since_last_purchase is better (higher score)
        -- We use a descending order for Recency to assign higher scores to more recent customers
        ntile(5) over (order by days_since_last_purchase desc) as r_score,

        -- Frequency Score: Higher total_orders_placed is better (higher score)
        ntile(5) over (order by total_order_count asc) as f_score,

        -- Monetary Score: Higher total_revenue_generated is better (higher score)
        ntile(5) over (order by life_time_customer_value asc) as m_score
    from customer_performance
),

rfm_segments as (
    -- Combine RFM scores into a single RFM segment string
    select
        customer_id,
        r_score,
        f_score,
        m_score,
        cast(r_score as string) || cast(f_score as string) || cast(m_score as string) as rfm_segment_score
    from rfm_scores
)

select
    rs.customer_id,
    rs.r_score,
    rs.f_score,
    rs.m_score,
    rs.rfm_segment_score,
    -- Assign customer segments based on RFM scores
    case
        when rs.r_score >= 4 and rs.f_score >= 4 and rs.m_score >= 4 then 'High-Value Loyal' -- Top tier customers
        when rs.r_score >= 4 and rs.f_score >= 3 and rs.m_score >= 3 then 'Loyal Customers' -- Good recency, frequency, monetary
        when rs.r_score >= 4 and rs.f_score <= 2 and rs.m_score <= 2 then 'New Customers' -- Recent but low frequency/monetary (could be new)
        when rs.r_score <= 2 and rs.f_score >= 4 and rs.m_score >= 4 then 'At-Risk Loyal' -- High frequency/monetary but not recent
        when rs.r_score <= 2 and rs.f_score <= 2 and rs.m_score <= 2 then 'Churned / Lost' -- Low across all metrics
        when rs.r_score >= 3 and rs.f_score <= 2 and rs.m_score >= 3 then 'Promising' -- Recent, good monetary, but low frequency
        when rs.r_score <= 2 and rs.f_score >= 3 and rs.m_score <= 2 then 'Needs Attention' -- Frequent, but not recent and low monetary
        else 'Other' -- Catch-all for remaining segments
    end as customer_segment
from 
    rfm_segments rs
order by 
    customer_id
