with source as (
    select * from {{ source('shopify', 'orders') }}
),

renamed as (
    select
        o_orderkey         as order_id,
        o_custkey          as customer_id,
        o_orderstatus      as order_status,
        o_totalprice       as order_total,
        o_orderdate        as ordered_at,
        o_orderpriority    as order_priority,
        o_clerk            as sales_rep,
        o_shippriority     as shipping_priority
    from source
)

select * from renamed