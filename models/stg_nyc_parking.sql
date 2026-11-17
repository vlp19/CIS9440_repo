select * 
from {{ source('nyc_parking', 'nyc_parking_camera_violations') }}