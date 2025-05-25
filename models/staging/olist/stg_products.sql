with source as (
    select * from {{ ref('seed_olist_products') }}
),

renamed as (
    select
        product_id,
        INITCAP(REPLACE(product_category_name, '_', ' ')) as product_category,
        product_name_lenght as product_name_length,
        product_description_lenght as product_description_length,
        product_photos_qty,
        product_weight_g as product_weight_gm,
        product_length_cm,
        product_height_cm,
        product_width_cm
    from 
        source
    where
        product_id is not null
)

select * from renamed
