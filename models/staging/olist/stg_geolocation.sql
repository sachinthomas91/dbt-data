with source as (
    select * from {{ ref('seed_olist_geolocation_mod') }}
),

renamed as (
    select
        geolocation_zip_code_prefix as zip_code,
        INITCAP(geolocation_city) as city,
        INITCAP(geolocation_state) as state
    from 
        source
    where 
        geolocation_zip_code_prefix is not null
)

select
    *
from 
    renamed