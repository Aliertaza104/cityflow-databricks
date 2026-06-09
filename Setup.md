# 🔧 CityFlow — Setup Guide

Complete step-by-step guide to set up and run the CityFlow Data Lakehouse project from scratch.

---

## Prerequisites

- AWS Account (Free Tier works)
- Databricks Free Edition Account
- NYC Taxi CSV dataset (download link below)

---

## Step 1 — Create AWS S3 Bucket

1. Go to [AWS Console](https://console.aws.amazon.com)
2. Search **S3** in the search bar → Click **Create bucket**
3. Configure the following settings:
   - **Bucket name:** `cityflow-taxi-data`
   - **Region:** `us-east-1` (N. Virginia)
   - **Object Ownership:** ACLs disabled (recommended)
   - **Block all public access:** ✅ ON
   - **Bucket Versioning:** Disable
   - **Default encryption:** SSE-S3 (default)
4. Click **Create bucket**

### Create Folder Structure

Navigate inside the bucket and create the following folders one by one:

```
cityflow-taxi-data/
├── raw/
│   └── taxi/        ← Upload NYC Taxi CSV file here
├── bronze/
├── silver/
└── gold/
```

> To create a folder: Open bucket → Click **Create folder** → Enter folder name → Save

### Upload Dataset

1. Download Yellow Taxi trip data from [NYC TLC Website](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
   - Recommended: `yellow_tripdata_2016-01.csv` (~1.6 GB)
2. Navigate to `raw/taxi/` folder inside your S3 bucket
3. Click **Upload** → Select the CSV file → Click **Upload**
4. Wait for upload to complete (may take 20-30 minutes depending on internet speed)

---

## Step 2 — Create AWS IAM User & Access Keys

This step creates a dedicated user for Databricks to access S3 securely.

1. Go to [AWS Console](https://console.aws.amazon.com) → Search **IAM**
2. Click **Users** → **Create user**
3. Configure:
   - **Username:** `databricks-s3-user`
   - **AWS Console access:** Not required
4. Click **Next** → **Attach policies directly**
5. Search and select **AmazonS3FullAccess** → Click **Next**
6. Click **Create user**

### Generate Access Keys

1. Click on `databricks-s3-user` → Go to **Security credentials** tab
2. Scroll down to **Access keys** → Click **Create access key**
3. **Use case:** Select **Other** → Click **Next**
4. **Description:** `databricks-access` → Click **Create access key**
5. ⚠️ **IMPORTANT:** Copy both keys or click **Download .csv file**
   - `Access Key ID` — starts with `AKIA...`
   - `Secret Access Key` — shown only once, never again!

---

## Step 3 — Set Up Databricks Free Edition

1. Go to [databricks.com](https://www.databricks.com)
2. Click **"Try Databricks"** → Sign up for **Free Edition**
3. Enter your details and verify your email
4. Wait for workspace to be provisioned (takes 2-3 minutes)
5. You will have access to:
   - Serverless Compute (instant start, no cluster management)
   - SQL Warehouse
   - Databricks Workflows
   - Unity Catalog

---

## Step 4 — Configure Databricks Secrets

Secrets allow you to store credentials securely — they are never visible in plain text inside notebooks.

### 4.1 — Install Databricks SDK

Create a new notebook in Databricks and run:

```python
%pip install databricks-sdk
```

Restart the kernel after installation completes.

### 4.2 — Create Secret Scope

```python
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()

try:
    w.secrets.create_scope(scope="cityflow-secrets")
    print("✅ Scope created successfully!")
except Exception as e:
    print(f"Scope already exists or error: {e}")
```

### 4.3 — Add Your Credentials

```python
# AWS Access Key (from Step 2)
w.secrets.put_secret(
    scope="cityflow-secrets",
    key="aws-access-key",
    string_value="YOUR_AWS_ACCESS_KEY_HERE"
)
print("✅ AWS Access Key saved!")

# AWS Secret Key (from Step 2)
w.secrets.put_secret(
    scope="cityflow-secrets",
    key="aws-secret-key",
    string_value="YOUR_AWS_SECRET_KEY_HERE"
)
print("✅ AWS Secret Key saved!")

# OpenAQ API Key — optional, get free key from openaq.org
w.secrets.put_secret(
    scope="cityflow-secrets",
    key="openaq-api-key",
    string_value="YOUR_OPENAQ_API_KEY_HERE"
)
print("✅ OpenAQ API Key saved!")
```

### 4.4 — Verify All Secrets

```python
secrets_list = w.secrets.list_secrets(scope="cityflow-secrets")
for s in secrets_list:
    print(f"✅ {s.key}")
```

Expected output:
```
✅ aws-access-key
✅ aws-secret-key
✅ openaq-api-key
```

### 4.5 — Test S3 Connection

```python
import urllib.parse

ACCESS_KEY = dbutils.secrets.get(scope="cityflow-secrets", key="aws-access-key")
SECRET_KEY = dbutils.secrets.get(scope="cityflow-secrets", key="aws-secret-key")
encoded_secret = urllib.parse.quote(SECRET_KEY, safe="")

df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv(f"s3a://{ACCESS_KEY}:{encoded_secret}@cityflow-taxi-data/raw/taxi/yellow_tripdata_2016-01.csv")

print(f"✅ S3 connection working!")
print(f"✅ Total rows: {df.count()}")
```

Expected output:
```
✅ S3 connection working!
✅ Total rows: 10906858
```

---

## Step 5 — Run Notebooks in Order

| Order | Notebook | Purpose | Expected Output |
|-------|----------|---------|----------------|
| 1 | `01_bronze_ingestion.ipynb` | Load raw CSV → Delta Lake | 10,906,858 records |
| 2 | `02_silver_transformation.ipynb` | Clean + validate data | 10,836,815 clean records |
| 3 | `03_gold_layer.ipynb` | Business aggregations | Daily + hourly summaries |
| 4 | `04_streaming_openaq.ipynb` | Fetch air quality data | 24 hourly measurements |
| 5 | `05_unity_catalog.ipynb` | Register tables + governance | 3 tables registered |

---

## Step 6 — Set Up Automated Workflows (Optional)

1. Go to Databricks → **Jobs & Pipelines** → **Create job**
2. Job name: `cityflow_pipeline`
3. Add tasks in the following order:

| Task Name | Notebook | Depends On |
|-----------|----------|------------|
| `bronze_ingestion` | `01_bronze_ingestion` | — |
| `silver_transformation` | `02_silver_transformation` | `bronze_ingestion` |
| `gold_layer` | `03_gold_layer` | `silver_transformation` |
| `streaming_airquality` | `04_streaming_openaq` | `gold_layer` |

4. Set schedule: **Add trigger** → **Scheduled** → Daily → `02:00 AM` → Your timezone
5. Click **Save**

---

## Step 7 — Set Up Unity Catalog (Optional)

Run `05_unity_catalog.ipynb` which will:
- Create `cityflow` catalog
- Create `bronze`, `silver`, `gold` schemas
- Register all Delta tables
- Add column-level documentation
- Enable automatic data lineage tracking

---

## Project Architecture

```
NYC Taxi CSV (AWS S3)
        ↓
┌─────────────────────────────────────┐
│         Databricks Platform         │
│                                     │
│  Bronze Layer  →  Raw Delta Table   │
│       ↓                             │
│  Silver Layer  →  Cleaned Data      │
│       ↓                             │
│  Gold Layer    →  Aggregations      │
│                                     │
│  + Air Quality Streaming            │
│  + Automated Workflows              │
│  + Unity Catalog Governance         │
│  + SQL Dashboard                    │
└─────────────────────────────────────┘
```

---

## ⚠️ Security Best Practices

- **NEVER** hardcode credentials inside notebooks
- **NEVER** push `.env` files or credential files to GitHub
- Always use `dbutils.secrets.get()` to access credentials
- Grant IAM user only **S3 access** — not full admin privileges
- Rotate access keys every 90 days

---

## 🆘 Common Issues & Solutions

| Issue | Error Message | Solution |
|-------|--------------|----------|
| S3 access denied | `AccessDenied` | Verify IAM user has `AmazonS3FullAccess` |
| Secret not found | `Secret not found` | Check scope name is exactly `cityflow-secrets` |
| Config not available | `CONFIG_NOT_AVAILABLE` | Use `dbutils.secrets` instead of `spark.conf.set` |
| JVM not supported | `JVM access not supported` | Use URL-embedded credentials for Serverless |
| Column not found | `UNRESOLVED_COLUMN` | 2016 data uses `pickup_longitude` instead of `PULocationID` |
| Path not found | `PATH_NOT_FOUND` | Check S3 bucket name and folder path are correct |
| Hive Metastore disabled | `UC_HIVE_METASTORE_DISABLED` | Change catalog from `hive_metastore` to `workspace` in SQL Editor |

---

## 📊 Expected Final Results

| Metric | Value |
|--------|-------|
| Raw records loaded | 10,906,858 |
| Clean records (Silver) | 10,836,815 |
| Removed dirty records | 70,043 |
| Date range covered | January 2016 |
| Total revenue tracked | $168,847,449 |
| Gold tables created | 2 |
| Air quality records | 96 (hourly) |
| Automated pipeline duration | ~2 minutes 12 seconds |

---

## 📬 Contact

**GitHub:** [Aliertaza104](https://github.com/Aliertaza104)

If you run into any issues not covered above, feel free to open an **Issue** on this repository.
