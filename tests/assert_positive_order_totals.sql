-- Every fulfilled order should have positive net revenue.
-- If this fails, Finance has a bad day.

select
    order_id,
    net_item_revenue
from {{ ref('fct_orders') }}
where order_status_clean = 'fulfilled'
  and net_item_revenue <= 0