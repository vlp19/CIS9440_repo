-- Date dimension shared by DOT 311 service requests and DOB NOW job filings
-- Build initial CTEs for Jinja syntax to make refs to staging models easier
with
    stg_311 as (select * from {{ ref("stg_nyc_311_dot") }}),

    stg_dob as (select * from {{ ref("stg_nyc_dob_job_filings") }}),

    -- Then union dates from the staging data together, collecting all poss dates
    all_dates as (

        -- 311 service requests: date roles referenced by fact_311_service_request
        select distinct cast(created_date as date) as full_date
        from stg_311
        where created_date is not null

        union distinct

        select distinct cast(closed_date as date) as full_date
        from stg_311
        where closed_date is not null

        union distinct

        -- DOB NOW job filings: date roles referenced by fact_dob_job_filing
        select distinct cast(filing_date as date) as full_date
        from stg_dob
        where filing_date is not null

        union distinct

        select distinct cast(current_status_date as date) as full_date
        from stg_dob
        where current_status_date is not null

        union distinct

        select distinct cast(first_permit_date as date) as full_date
        from stg_dob
        where first_permit_date is not null

        union distinct

        select distinct cast(approved_date as date) as full_date
        from stg_dob
        where approved_date is not null

        union distinct

        select distinct cast(signoff_date as date) as full_date
        from stg_dob
        where signoff_date is not null

    ),

    -- Date dimension with NYC fiscal year, Jul 1 - Jun 30, diff from federal
    date_dimension as (

        select
            {{ dbt_utils.generate_surrogate_key(["full_date"]) }} as date_key,

            full_date,
            extract(year from full_date) as year,
            extract(quarter from full_date) as quarter,
            extract(month from full_date) as month,
            format_date('%B', full_date) as month_name,
            extract(day from full_date) as day_of_month,
            extract(dayofweek from full_date) as day_of_week,
            format_date('%A', full_date) as weekday_name,
            extract(dayofweek from full_date) in (1, 7) as is_weekend,

            case
                when extract(month from full_date) >= 7
                then extract(year from full_date) + 1
                else extract(year from full_date)
            end as fiscal_year

        from all_dates

    ),

    -- Null placeholder row: to handle NULL values.
    -- Building fact tables should COALESCE a null source date to this key
    -- Keeps all fact and date_dim joins INNER JOINs safely
    -- Kimball convention to be explicit. (More to come on this)
    null_placeholder as (

        select
            '-1' as date_key,
            cast(null as date) as full_date,
            cast(null as int64) as year,
            cast(null as int64) as quarter,
            cast(null as int64) as month,
            cast(null as string) as month_name,
            cast(null as int64) as day_of_month,
            cast(null as int64) as day_of_week,
            cast(null as string) as weekday_name,
            cast(null as boolean) as is_weekend,
            cast(null as int64) as fiscal_year
    )
-- make sure BQ knows the col types
select *
from date_dimension

union all

select *
from null_placeholder
