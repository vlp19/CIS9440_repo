select
    {{ dbt_utils.generate_surrogate_key(['unique_key']) }} as services_request_key,
    {{ dbt_utils.generate_surrogate_key(['agency']) }} as request_agency_key,
    {{ dbt_utils.generate_surrogate_key(['borough', 'incident_zip']) }} as location_key,
    1 as request_count
from {{ ref('stg_nyc_311') }}