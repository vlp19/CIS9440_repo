-- Clean and standardize DOB NOW Job Filings data
-- One row per unique job filing

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_dob_now_homework') }}
), 

cleaned AS (
   SELECT
      -- Get all columns from source, except ones we're transforming below
      * EXCEPT (
          job_filing_number,
          filing_date,
          borough,
          zip_code,
          house_number,
          street_name,
          work_type
      ),

      -- Identifiers
      CAST(job_filing_number AS STRING) AS job_filing_id,

      -- Date/Time
      CAST(filing_date AS TIMESTAMP) AS filing_date,

      -- Job details
      UPPER(TRIM(CAST(job_status AS STRING))) AS job_status,
      UPPER(TRIM(CAST(work_type AS STRING))) AS work_type,

      -- Location - clean zip code, handling common zip code data problems
      CASE
          WHEN UPPER(TRIM(CAST(zip_code AS STRING))) IN ('N/A', 'NA', 'NULL') THEN NULL
          WHEN LENGTH(CAST(zip_code AS STRING)) = 5 THEN CAST(zip_code AS STRING)
          WHEN LENGTH(CAST(zip_code AS STRING)) = 9 THEN CAST(zip_code AS STRING)
          WHEN LENGTH(CAST(zip_code AS STRING)) = 10 
              AND REGEXP_CONTAINS(CAST(zip_code AS STRING), r'^\d{5}-\d{4}') 
          THEN CAST(zip_code AS STRING)
          ELSE NULL
      END AS zip,

      -- Location - standardized borough
      CASE
          WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
          WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
          WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
          WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
          WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
          ELSE 'UNKNOWN or CITYWIDE'
      END AS borough,

      CAST(house_number AS STRING) AS house_number,
      CAST(street_name AS STRING) AS street_name,

      -- Metadata
      CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE job_filing_number IS NOT NULL
   AND filing_date IS NOT NULL
   AND CAST(filing_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)

SELECT * FROM cleaned