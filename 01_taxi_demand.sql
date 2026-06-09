-- NYC Taxi Hourly Demand Query
SELECT pickup_hour, pickup_day,
       total_trips, avg_fare
FROM cityflow.gold.hourly_demand
ORDER BY pickup_hour;