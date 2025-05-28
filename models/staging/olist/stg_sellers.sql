with source as (
    select * from {{ ref('seed_olist_sellers') }}
),

renamed as (
    select
        seller_id,
        seller_zip_code_prefix as seller_zip_code,
        INITCAP(seller_city) as seller_city,
        INITCAP(seller_state) as seller_state
    from 
        source
    where 
        seller_id is not null
)

select * from renamed
