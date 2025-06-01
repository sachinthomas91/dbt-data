{{ config(
    description="Wide table combining marketing qualified lead data with seller performance metrics to analyze marketing channel effectiveness and seller success"
) }}

with fact_closed_deals as (
    select * from {{ ref('fact_closed_deals') }}
),

seller_performance as (
    select * from {{ ref('agg_seller_performance') }}
),

combined_data as (
    select
        -- Marketing and Deal Information
        cd.mql_id,
        cd.seller_id,
        cd.mql_first_contact_date,
        cd.deal_closed_datetime,
        cd.days_to_close,
        cd.mql_origin_category,
        cd.lead_business_segment,
        cd.lead_business_category,
        cd.lead_behaviour_profile_category,
        cd.lead_business_monthly_revenue as declared_monthly_revenue,
        cd.lead_business_product_catalog_size as declared_catalog_size,
        cd.lead_business_average_stock as declared_avg_stock,
        cd.has_company,
        cd.has_gtin,

        -- Actual Seller Performance Metrics
        sp.first_sale_date,
        sp.last_sale_date,
        sp.days_since_last_sale,
        sp.life_time_seller_sales_value,
        sp.avg_sale_value,
        sp.lost_revenue_canceled,
        sp.lost_revenue_unavailable,
        sp.avg_review_score,
        sp.seller_status,

        -- Calculated Performance Indicators
        round(sp.life_time_seller_sales_value / nullif(cd.lead_business_monthly_revenue, 0), 2) as actual_vs_declared_revenue_ratio,
        date_diff(sp.first_sale_date, date(cd.deal_closed_datetime), DAY) as days_to_first_sale,
        sp.avg_monthly_orders,
        sp.avg_monthly_revenue,
        sp.order_problem_rate

    from fact_closed_deals cd
    left join seller_performance sp 
        on cd.seller_id = sp.seller_id
)

select
     *
    ,case
        when actual_vs_declared_revenue_ratio >= 1.2 then 'Exceptional Performance'
        when actual_vs_declared_revenue_ratio >= 1.0 then 'Above Expectations'
        when actual_vs_declared_revenue_ratio >= 0.8 then 'Meeting Expectations'
        when actual_vs_declared_revenue_ratio >= 0.5 then 'Underperforming'
        else 'Severely Underperforming'
    end as revenue_performance_category
from 
    combined_data
order by 
    mql_first_contact_date desc
