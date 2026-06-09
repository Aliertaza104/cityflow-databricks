# 🏙️ CityFlow — Data Lakehouse on Databricks

Production-grade medallion architecture using NYC Taxi data.

## 🏗️ Architecture

Raw CSV (S3) → Bronze (Delta) → Silver (Delta) → Gold (Delta)
                                                      ↓
                                              Dashboard + Unity Catalog
                                              
## 📊 Project Stats
- **10.9M** raw records processed
- **10.8M** clean records in Silver layer
- **$168M** revenue tracked (Jan 2016)
- **2min 12sec** automated pipeline runtime
- **2** data sources: NYC Taxi + Air Quality

## 🛠️ Tech Stack
| Tool | Purpose |
|------|---------|
| Databricks Free Edition | Main platform |
| Apache Spark 4.1.0 | Data processing |
| Delta Lake | Storage format |
| AWS S3 | Cloud storage |
| Databricks Workflows | Pipeline automation |
| Unity Catalog | Data governance |
| Open-Meteo API | Real-time air quality |

## 📁 Project Structure
- `01_bronze_ingestion.py` — Raw data ingestion → Delta Lake
- `02_silver_transformation.py` — Data cleaning + validation
- `03_gold_layer.py` — Business aggregations
- `04_streaming_openaq.py` — Air quality streaming
- `05_unity_catalog.sql` — Data governance setup

## 🔐 Security
All credentials stored in **Databricks Secrets** — no hardcoded keys anywhere.

## 📈 Dashboard
- NYC Taxi Demand Heatmap (hour × day)
- Air Quality Trend (PM2.5, PM10, Ozone)

## 🚀 Automated Pipeline
Databricks Workflows — Daily 2:00 AM (Asia/Karachi)

`bronze_ingestion` → `silver_transformation` → `gold_layer` → `streaming_airquality`
