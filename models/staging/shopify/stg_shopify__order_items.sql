with source as (
    select * from {{ source('shopify', 'line_items') }}
),

renamed as (
    select
        l_orderkey         as order_id,
        l_partkey          as product_id,
        l_linenumber       as line_number,
        l_quantity         as quantity,
        l_extendedprice    as line_total,
        l_discount         as discount_pct,
        l_shipdate         as shipped_at,
        l_returnflag       as return_flag
    from source
)

select * from renamed