{{
    config(
        materialized='table'
    )
}}

with customers as (
    select * from {{ ref('stg_shopify__customers') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

customer_orders as (
    select
        customer_id,
        count(distinct order_id)    as lifetime_order_count,
        sum(net_item_revenue)       as lifetime_revenue,
        min(ordered_at)             as first_order_date,
        max(ordered_at)             as most_recent_order_date
    from orders
    group by 1
),

final as (
    select
        c.customer_id,
        c.customer_name,
        c.market_segment,
        c.account_balance,
        coalesce(co.lifetime_order_count, 0) as lifetime_order_count,
        coalesce(co.lifetime_revenue, 0)     as lifetime_revenue,
        co.first_order_date,
        co.most_recent_order_date,
        case
            when co.lifetime_order_count >= 10 then 'high_value'
            when co.lifetime_order_count >= 3  then 'repeat'
            when co.lifetime_order_count = 1   then 'one_time'
            else 'prospect'
        end as customer_segment
    from customers c
    left join customer_orders co
        on c.customer_id = co.customer_id
)

select * from final