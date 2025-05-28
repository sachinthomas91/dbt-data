with source as (
    select * from {{ ref('stg_customers') }}
)

select distinct
    src.customer_id,
    src.customer_zip_code as customer_zip_code,
    COALESCE(gl.city, src.customer_city) as customer_city,
    COALESCE(gl.state, src.customer_state) as customer_state
from
    source src
    left join {{ ref('stg_geolocation') }} as gl
        on src.customer_zip_code = gl.zip_code