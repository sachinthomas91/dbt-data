{% macro standardize_to_datetime(column_name) %}
    case
        when {{ column_name }} is null or trim({{ column_name }}) = '' then null
        else 
            -- Clean and standardize the datetime string once
            case
                when regexp_contains(
                    {{ clean_datetime_string(column_name) }},
                    r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
                )
                    then parse_datetime(
                        '%Y-%m-%d %H:%M:%S',
                        {{ clean_datetime_string(column_name) }}
                    )
                when regexp_contains(
                    {{ clean_datetime_string(column_name) }},
                    r'^\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2}$'
                )
                    then parse_datetime(
                        '%m-%d-%Y %H:%M:%S',
                        {{ clean_datetime_string(column_name) }}
                    )
                -- Handle date-only inputs (no time)
                when regexp_contains(
                    {{ clean_datetime_string(column_name) }},
                    r'^\d{4}-\d{2}-\d{2}$'
                )
                    then parse_datetime(
                        '%Y-%m-%d',
                        {{ clean_datetime_string(column_name) }}
                    )
                when regexp_contains(
                    {{ clean_datetime_string(column_name) }},
                    r'^\d{2}-\d{2}-\d{4}$'
                )
                    then parse_datetime(
                        '%m-%d-%Y',
                        {{ clean_datetime_string(column_name) }}
                    )
                else null
            end
    end
{% endmacro %}