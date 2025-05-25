-- Custom macro to generate schema names based on environment and custom schema name
-- This macro generates a schema name based on the provided custom schema name and the target environment
{% macro generate_schema_name(custom_schema_name, node) %}
    {%- set env = target.name -%}
    {%- set base_schema = custom_schema_name if custom_schema_name is not none else target.schema -%}
    {%- if env == 'dev' -%}
        {{ base_schema }}_dev
    {%- elif env == 'uat' -%}
        {{ base_schema }}_uat
    {%- else -%}
        {{ base_schema }}
    {%- endif -%}
{% endmacro %}
