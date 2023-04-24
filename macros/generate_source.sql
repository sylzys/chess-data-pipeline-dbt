{% macro generate_source(database_name, schema_name, source_name) %}

{% set sql %}
    with "columns" as (
        select '- name: ' || lower(column_name) || '\n            description: "'|| lower(column_name) || ' (snowflake data type: '|| lower(DATA_TYPE) || ')"'
            as column_statement,
            table_name,
            column_name
        from {{ database_name }}.information_schema.columns
        where table_schema = '{{ schema_name | upper }}' and table_name not in ('FIVETRAN_AUDIT', 'SCHEMA_MIGRATIONS')
            and lower(column_name) not in ('_fivetran_deleted', '_fivetran_synced')
    ),
    tables as (
        select table_name,
        '\n      - name: ' || lower(table_name) || '\n        columns:' || listagg('\n          ' || column_statement || '\n') within group ( order by column_name ) as table_desc
        from "columns"
        group by table_name
    )

    select listagg(table_desc) within group ( order by table_name )
    from tables;
{% endset %}

{%- call statement('generator', fetch_result=True) -%}
{{ sql }}
{%- endcall -%}

{%- set states=load_result('generator') -%}
{%- set states_data=states['data'] -%}
{%- set states_status=states['response'] -%}

{% set sources_yaml=[] %}
{% do sources_yaml.append('version: 2') %}
{% do sources_yaml.append('') %}
{% do sources_yaml.append('sources:') %}
{% do sources_yaml.append('  - name: ' ~ source_name | lower) %}
{% do sources_yaml.append('    description: ""' ) %}
{% do sources_yaml.append('    database: ' ~ database_name | lower) %}
{% do sources_yaml.append('    schema: ' ~ schema_name | lower) %}
{% do sources_yaml.append('    loader: fivetran') %}
{% do sources_yaml.append('    loaded_at_field: _FIVETRAN_SYNCED') %}
{% do sources_yaml.append('    meta:') %}
{% do sources_yaml.append('      owner: ""') %}
{% do sources_yaml.append('      tags: [""]') %}
{% do sources_yaml.append('      subscribers: ["@data-team"]') %}

{% do sources_yaml.append('    tables:' ~ states_data[0][0] ) %}

{% if execute %}

{% set joined = sources_yaml | join ('\n') %}
{{ log(joined, info=True) }}
{% do return(joined) %}

{% endif %}

{% endmacro %}