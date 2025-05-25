with source as (
    select * from {{ ref('seed_olist_sellers') }}
),

renamed as (
    select
        seller_id,
        seller_zip_code_prefix as seller_zip_code,
        seller_city,
        seller_state
    from 
        source
    where 
        seller_id is not null
)

select * from renamed
