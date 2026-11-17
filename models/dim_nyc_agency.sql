select distinct
    {{ dbt_utils.generate_surrogate_key(['agency']) }} as agency_key,
    agency as agency_name
from {{ ref('stg_nyc_311') }}
where agency is not null