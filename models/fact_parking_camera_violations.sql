select
    {{ dbt_utils.generate_surrogate_key(['summons_number']) }} as summons_key,
    {{ dbt_utils.generate_surrogate_key(['borough', 'precinct']) }} as location_key,
    {{ dbt_utils.generate_surrogate_key(['issuing_agency']) }} as agency_key,
    fine_amount,
    penalty_amount,
    interest_amount
from {{ ref('stg_nyc_parking') }}