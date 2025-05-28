with source as (
    select * from {{ ref('stg_sellers') }}
)

select 
    seller_id,
    src.seller_zip_code as seller_zip_code,
    COALESCE(gl.city, src.seller_city) as seller_city,
    COALESCE(gl.state, src.seller_state) as seller_state
from
    source src
    left join {{ ref('stg_geolocation') }} as gl
        on src.seller_zip_code = gl.zip_code