with source as (
    select * from {{ ref('seed_olist_order_payments') }}
),

renamed as (
    select
        order_id,
        payment_sequential as payment_type_sequence,
        INITCAP(REPLACE(payment_type, '_', ' ')) as payment_type,
        case
            when payment_installments=0 then 1
            else payment_installments
        end as payment_installment_count,
        payment_value
    from 
        source
    where 
        order_id is not null
)

select * from renamed
