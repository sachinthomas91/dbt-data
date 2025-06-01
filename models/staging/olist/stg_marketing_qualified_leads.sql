{{ config(
    description="Staging model for marketing qualified leads related to Olist's marketing campaigns"
) }}

with source as (
    select * from {{ ref('seed_olist_marketing_qualified_leads') }}
),

renamed as (
    select
        mql_id,
        date(first_contact_date) as mql_first_contact_date,
        landing_page_id as mql_landing_page_id,
        INITCAP(REPLACE(origin, '_', ' ')) as mql_origin_category
    from 
        source
    where 
        mql_id is not null
)

select * from renamed
