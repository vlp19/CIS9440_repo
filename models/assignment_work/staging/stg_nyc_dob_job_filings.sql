

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_dob_now_homework') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           current_status_date,
           borough,
           zip,
           postcode,
           latitude,
           existing_dwelling_units,
           proposed_height,
           filing_status,
           building_type
       ),

       -- Identifiers
       CAST (bin AS STRING) as bin,
       CAST (bbl AS STRING) as bbl,

       -- Date/Time
       CAST (current_status_date AS TIMESTAMP) AS current_status_date, 

       -- Request details
       CAST(agency AS STRING) AS agency,
       CAST(agency_name AS STRING) AS agency_name,
       CAST(complaint_type AS STRING) AS complaint_type,
       CAST(descriptor AS STRING) AS descriptor,
       UPPER(TRIM(CAST(status AS STRING))) AS status,

       -- Location - clean zip code, handling several common zip code data problems
       CASE
            WHEN UPPER(TRIM(CAST(COALESCE(zip, postcode) AS STRING))) IN ('N/A', 'NA', 'NONE') THEN NULL
            WHEN LENGTH(CAST(COALESCE(zip, postcode) AS STRING)) = 5 THEN CAST(COALESCE(zip, postcode) AS STRING)
            WHEN LENGTH(CAST(COALESCE(zip, postcode) AS STRING)) = 9 THEN CAST(COALESCE(zip, postcode) AS STRING)
            WHEN LENGTH(CAST(COALESCE(zip, postcode) AS STRING)) = 10
                AND REGEXP_CONTAINS(CAST(COALESCE(zip, postcode) AS STRING), r'^\d{5}-\d{4}')
            THEN CAST(COALESCE(zip, postcode) AS STRING)
            ELSE NULL
        END AS zip,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(incident_dwelling_units AS INT64) AS existing_dwelling_units,
       CAST(proposed_height AS DECIMAL) AS proposed_height,

       -- Clearer column name as well for this one
       UPPER(TRIM(CAST(filing_status AS STRING))) AS filing_status,
       UPPER(TRIM(CAST(building_type AS STRING))) AS building_type,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE bin IS NOT NULL
   AND borough IS NOT NULL
   AND current_status_date IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY bin, current_status_date ORDER BY current_status_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_311_dot
