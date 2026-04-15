{{
    config(
        materialized='table'
    )
}}

with orders as (
    select * from {{ ref('stg_shopify__orders') }}
),

order_items as (
    select * from {{ ref('stg_shopify__order_items') }}
),

item_aggregates as (
    select
        order_id,
        count(*)                              as item_count,
        sum(quantity)                         as total_quantity,
        sum(line_total)                       as gross_item_revenue,
        sum(line_total * (1 - discount_pct))  as net_item_revenue
    from order_items
    group by 1
),

final as (
    select
        o.order_id,
        o.customer_id,
        o.ordered_at,
        o.order_status,
        o.order_priority,
        o.order_total,
        i.item_count,
        i.total_quantity,
        i.gross_item_revenue,
        i.net_item_revenue,
        case
            when o.order_status = 'F' then 'fulfilled'
            when o.order_status = 'O' then 'open'
            when o.order_status = 'P' then 'pending'
            else 'unknown'
        end as order_status_clean,
        case 
            when net_item_revenue > 50000 then true 
            else false 
        end as is_high_value_order
    from orders o
    left join item_aggregates i
        on o.order_id = i.order_id
)

select * from final