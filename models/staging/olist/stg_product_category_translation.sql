with source as (
    select * from {{ ref('seed_olist_product_category_name_translation') }}
),

renamed as (
    select
        INITCAP(REPLACE(product_category_name, '_', ' ')) as product_category_name,
        INITCAP(REPLACE(product_category_name_english, '_', ' ')) as product_category_name_english
    from 
        source
    where 
        product_category_name is not null
)

select * from renamed
