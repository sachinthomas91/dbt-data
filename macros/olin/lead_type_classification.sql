{% macro classify_olin_lead_type(lead_type) %}
    case
        when {{ lead_type }} like 'online%' then 'Online'
        when {{ lead_type }} = 'offline' then 'Offline'
        else null
    end as lead_business_channel_category,
    case
        when {{ lead_type }} = 'online_beginner' then 'Beginner'
        when {{ lead_type }} = 'online_small' then 'Small'
        when {{ lead_type }} = 'online_medium' then 'Medium'
        when {{ lead_type }} = 'online_big' then 'Big'
        when {{ lead_type }} = 'online_top' then 'Top'
        when {{ lead_type }} = 'other' then 'Other'
        when {{ lead_type }} = 'industry' then 'Industry'
        else null
    end as lead_business_tier
{% endmacro %}
