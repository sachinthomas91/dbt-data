with source as (
    select * from {{ ref('stg_customers') }}
)

, geolocation as (
    select * from {{ ref('stg_geolocation') }}
)

select distinct
    src.customer_id,
    src.order_customer_id,
    src.customer_zip_code as customer_zip_code,
    COALESCE(gl.city, src.customer_city) as customer_city,
    COALESCE(gl.state, src.customer_state) as customer_state
from
    source src
    left join geolocation gl
        on src.customer_zip_code = gl.zip_code