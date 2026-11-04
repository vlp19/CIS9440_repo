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
            filing_date
        ),

        -- Identifiers
        CAST(job_filing_number AS STRING) AS job_filing_id,

        -- Date/Time
        CAST(filing_date AS TIMESTAMP) AS filing_date,

        -- Job details
        UPPER(TRIM(CAST(job_type AS STRING))) AS job_type,

        -- Geographic attributes available in schema
        CAST(nta AS STRING) AS nta,
        CAST(council_district AS INTEGER) AS council_district,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    WHERE job_filing_number IS NOT NULL
    AND filing_date IS NOT NULL
    AND CAST(filing_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)

SELECT * FROM cleaned