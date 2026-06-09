-- NYC Air Quality Trend Query
SELECT measured_at,
       pm2_5,
       pm10,
       ozone,
       nitrogen_dioxide
FROM cityflow.bronze.airquality
ORDER BY measured_at;
