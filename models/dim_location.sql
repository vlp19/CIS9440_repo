select distinct
    {{ dbt_utils.generate_surrogate_key(['borough', 'precinct']) }} as location_key,
    borough,
    precinct
from {{ ref('stg_nyc_parking') }}
where borough is not null