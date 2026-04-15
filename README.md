# Cedar & Pine Home Co. — dbt Cloud Reference Implementation

A reference dbt Cloud project built as part of my Solutions Architect interview prep for dbt Labs. The goal of this repo is not to demonstrate analytics engineering craft (though the patterns here are production-grade); it is to demonstrate how I would walk a Commercial prospect through dbt Cloud's value proposition, anchored to a realistic customer pain narrative.

---

## The Prospect

**Cedar & Pine Home Co.** is a fictional direct-to-consumer home goods brand designed to represent a typical Commercial-tier dbt Labs prospect. The profile below is intentionally specific so the technical decisions in this repo map cleanly to a real sales motion.

**Profile**
- **Industry:** DTC e-commerce (home goods, furniture, decor)
- **Size:** ~280 employees, ~$75M ARR
- **Stage:** Series C, profitable, growing 40% YoY
- **HQ:** Austin, TX
- **Data team:** 1 Analytics Engineer, 3 Analysts, 1 Data Engineer, reporting to VP Finance

**Current stack**
- **Warehouse:** Snowflake (Standard tier, ~$18K/month spend)
- **Ingestion:** Fivetran from Shopify, Stripe, Klaviyo, NetSuite, Zendesk
- **Transformation:** dbt Core, self-hosted on an EC2 instance running via cron
- **BI:** Looker
- **Orchestration:** None formal. Cron + Slack alerts when things break.

**The pain**

Cedar & Pine's data team is firefighting more than building. Five specific problems surfaced in discovery:

1. **No CI.** Analysts push changes to `main` and hope nothing breaks. Last month a bad join doubled revenue numbers in the exec dashboard for 36 hours.
2. **Warehouse costs growing 20% QoQ.** Every dbt run rebuilds the world because no one set up Slim CI or incremental logic correctly.
3. **Inconsistent metrics across Looker.** Three different definitions of "active customer" floating around. Finance and Marketing fight about it weekly.
4. **The Analytics Engineer is a bottleneck.** Every analyst waits on her to review PRs because there is no automated testing.
5. **No visibility into lineage.** When a Shopify field changes upstream, no one knows what downstream models break until the dashboard turns red.

**The decision maker**

**Priya Patel, VP Finance and Data.** Ex-McKinsey, numbers person. Cares about three things: reducing warehouse spend, trusting the numbers in the board deck, and not hiring two more analytics engineers this year.

---

## The Pitch

**The 30-second version**

Priya, based on our discovery calls, your team is spending too much time firefighting and too much money rebuilding data that did not change. dbt Cloud solves three problems at once: Slim CI cuts your warehouse spend on every PR by only building what changed, the Semantic Layer gives Looker one canonical definition of "active customer" so Finance and Marketing stop arguing, and built-in testing catches bad joins before they hit your exec dashboard. The repo below shows all three working against a data shape that mirrors yours.

**The three product pillars**

| Pillar | Cedar & Pine pain | dbt Cloud feature | ROI anchor |
|---|---|---|---|
| **Trust** | Bad joins hit prod, no tests | Tests + CI + lineage | The 36-hour revenue error does not happen |
| **Speed + Cost** | Rebuilds everything on every run, warehouse cost up 20% QoQ | Slim CI with deferral | 30-50% reduction in CI compute |
| **Consistency** | 3 definitions of "active customer" | Semantic Layer | One metric, queried from Looker, Excel, anywhere |

---

## What's in this repo

- **Staging layer:** 3 models cleaning raw Shopify data (orders, customers, line items), materialized as views
- **Marts:** `fct_orders` (one row per order, with line item aggregates) and `dim_customers` (one row per customer, with lifetime revenue and behavioral segments)
- **Testing:** Generic tests on every primary key, foreign key, and accepted-value column, plus a singular test asserting that fulfilled orders have positive net revenue
- **Documentation:** Column-level descriptions on every model, lineage graph generated from `ref()` and `source()`
- **Source freshness:** Configured on Shopify orders to alert when raw data has not landed in 48 hours (warn) or 72 hours (error)
- **Slim CI:** A CI job configured to run only on modified models with deferral to the Production environment, so PRs build only what changed
- **Semantic Layer:** A daily time spine plus a semantic model on `fct_orders` exposing three metrics: `net_revenue`, `order_count`, and `average_order_value` (a ratio metric)


---

## Architecture decisions

**Why staging + marts, no intermediate layer?**

Cedar & Pine's data shape is simple enough that intermediate models would add complexity without value. The intermediate layer earns its place when there is reusable business logic that multiple marts share — for example, a sessionized clickstream that 4 different fact tables consume. At this scale, going staging → marts directly keeps the mental model clean for a 5-person data team. For an Enterprise customer with 200+ models, an intermediate layer becomes essential.

**Why are dim_customers' lifetime aggregates computed from fct_orders?**

Strict Kimball orthodoxy keeps dimensions independent of facts. I made a pragmatic choice to enrich `dim_customers` with order-derived attributes (`lifetime_revenue`, `customer_segment`, `first_order_date`) because BI tools and self-serve analysts want one wide customer table with everything pre-computed. This is the prevailing pattern in modern analytics engineering and is worth the small tradeoff in modeling purity.

**Why Slim CI instead of full rebuilds?**

Cedar & Pine's warehouse spend is up 20% QoQ. Slim CI with deferral cuts CI compute by only building models downstream of the change set on each PR. For a team running 20-30 PRs per week, this is a 60-80% reduction in CI spend with zero loss of safety, because the dependency graph guarantees nothing downstream is missed. This is the single feature most likely to pay back the dbt Cloud subscription within the first quarter.

**Why Semantic Layer vs. metrics in Looker?**

Cedar & Pine has three definitions of "active customer" across Looker dashboards. Defining metrics once in dbt and consuming them from Looker, Excel, the JDBC interface, and ad-hoc SQL means one source of truth. This is the specific pain Priya named on the discovery call. The semantic model in this repo defines `average_order_value` as a ratio metric — the kind of derived calculation that gets re-implemented inconsistently across BI tools, and the kind dbt's Semantic Layer is built to centralize.

**Why source freshness on Shopify orders?**

When ingestion silently fails, the dashboard does not turn red — it just shows yesterday's numbers. Configuring `loaded_at_field` and freshness thresholds means the data team gets alerted within hours, not days. The data in this repo is static TPC-H sample data, so the freshness check intentionally fires — that is the demonstration of the alerting mechanism, not a bug.

**Why use ref() and source() for everything?**

These are the conventions that power the rest of the platform. `ref()` builds the dependency graph, which enables Slim CI, deferral, dbt Catalog, and column-level lineage. `source()` decouples model code from physical schema location and enables freshness checks. Skipping either of these breaks the value chain.

---

## Rollout plan: what a 60-day Commercial deployment looks like

A realistic phased migration from Cedar & Pine's current dbt Core + cron setup to dbt Cloud:

- **Weeks 1-2:** Migrate the existing dbt Core project to dbt Cloud. Connect Snowflake and GitHub via the native integration. Stand up Development and Production environments mirroring current deployment.
- **Weeks 3-4:** Configure CI with Slim CI and deferral. Onboard the Analytics Engineer and 3 Analysts. Establish a PR template and review workflow.
- **Weeks 5-6:** Build the first 5 Semantic Layer metrics, starting with the ones Finance and Marketing currently disagree on. Connect Looker to the Semantic Layer.
- **Weeks 7-8:** Configure source freshness alerts and dbt Catalog for self-serve discovery. Hand off ownership to the internal team.

By week 8, the Analytics Engineer is reviewing code, not copy-pasting SQL fixes at 11pm. Warehouse spend shows a measurable drop. Finance and Marketing share one definition of every metric they argue about today.

---

## About me

**Tariq Dwekat** — Data Engineer transitioning to Solutions Architecture. Three years of production data engineering at AMD, Charles Schwab, Adobe, and Verizon. Stack centered on Snowflake, BigQuery, Python, SQL, and Kafka. 

[tariqdwekat.com](https://tariqdwekat.com) · [LinkedIn](https://www.linkedin.com/in/tariqdwekat/)