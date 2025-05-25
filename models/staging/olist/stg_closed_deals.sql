with source as (
    select * from {{ ref('seed_olist_closed_deals') }}
),

renamed as (
    select
        mql_id,
        seller_id,
        sdr_id,
        sr_id,
        {{ standardize_to_datetime('won_date') }} as deal_closed_datetime,
        INITCAP(REPLACE(business_segment, '_', ' ')) as lead_business_segment,
        {{ classify_olin_lead_type('lead_type') }},
        INITCAP(lead_behaviour_profile) as lead_behaviour_profile_category,
        has_company,
        has_gtin,
        average_stock as lead_business_average_stock,
        INITCAP(business_type) as lead_business_category,
        declared_product_catalog_size as lead_business_product_catalog_size,
        declared_monthly_revenue as lead_business_monthly_revenue
    from 
        source
    where 
        mql_id is not null 
        and seller_id is not null
)

select * from renamed
