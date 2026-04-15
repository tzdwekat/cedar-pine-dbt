{{
    config(
        materialized='table'
    )
}}

with days as (

    {{
        dbt.date_spine(
            'day',
            "to_date('2015-01-01')",
            "dateadd(year, 5, current_date)"
        )
    }}

),

final as (
    select cast(date_day as date) as date_day
    from days
)

select * from final