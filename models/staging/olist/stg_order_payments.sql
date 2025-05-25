with source as (
    select * from {{ ref('seed_olist_order_payments') }}
),

renamed as (
    select
        order_id,
        payment_sequential as payment_type_sequence,
        INITCAP(REPLACE(payment_type, '_', ' ')) as payment_type,
        payment_installments as payment_installment_row_number,
        payment_value
    from 
        source
    where 
        order_id is not null
)

select * from renamed
