with source as (
    select * from {{ ref('stg_products') }}
),

lookup_english_product_category as (
    select * from {{ ref('stg_product_category_translation') }}
)

select
    src.product_id,
    lkp.product_category_name_english as product_category,
    src.product_name_length,
    src.product_description_length,
    src.product_photos_qty,
    src.product_weight_gm,
    src.product_length_cm,
    src.product_height_cm,
    src.product_width_cm
from
    source src
    left join lookup_english_product_category lkp
        on src.product_category = lkp.product_category_name
