{{ config(
    description="Fact table combining closed deals with their originating marketing qualified leads, including all relevant deal and lead metrics"
) }}

with closed_deals as (
    select * from {{ ref('stg_closed_deals') }}
),

marketing_qualified_leads as (
    select * from {{ ref('stg_marketing_qualified_leads') }}
),

enriched_deals as (
    select
        -- Deal Identifiers
        cd.mql_id,
        cd.seller_id,
        cd.sdr_id,
        cd.sr_id,

        -- Deal Timestamps and Duration
        mql.mql_first_contact_date,
        cd.deal_closed_datetime,
        date_diff(cd.deal_closed_datetime, mql.mql_first_contact_date, DAY) as days_to_close,

        -- Marketing Source
        mql.mql_landing_page_id,
        mql.mql_origin_category,

        -- Business Profile
        cd.lead_business_segment,
        cd.lead_business_category,
        cd.lead_behaviour_profile_category,
        
        -- Business Metrics
        cd.has_company,
        cd.has_gtin,
        cd.lead_business_average_stock,
        cd.lead_business_product_catalog_size,
        cd.lead_business_monthly_revenue

    from closed_deals cd
    inner join marketing_qualified_leads mql 
        on cd.mql_id = mql.mql_id
)

select * from enriched_deals
