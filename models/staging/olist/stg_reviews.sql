with source as (
    select * from {{ ref('seed_olist_order_reviews') }}
),

renamed as (
    select
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date as review_creation_datetime,
        review_answer_timestamp as review_answer_datetime
    from 
        source
    where 
        review_id is not null 
        and order_id is not null
)

select * from renamed
