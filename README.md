# 🚀 Build a Real-Time Data Pipeline with Redpanda, ClickHouse, and Superset: A Step-by-Step Tutorial


![thumbnail](https://github.com/user-attachments/assets/e622a78d-6729-4e13-b125-3ee35dc57f63)



Welcome to this comprehensive tutorial on building a modern, real-time data pipeline! 🎉 Whether you're a data engineer, analyst, or enthusiast, this guide will walk you through creating a powerful system that processes data from an FTP server, streams it through Redpanda, stores it in ClickHouse, and visualizes it with Superset—all orchestrated with Docker. 🐳 By the end, you'll have a fully functional pipeline with interactive dashboards, perfect for real-time analytics. Let’s dive in! 🔍

## What You’ll Build 🛠️

This project creates a data pipeline that:
- 📥 Extracts compressed log files from an FTP server using Redpanda Connect’s sftp connector.
- 🔄 Tracks processed files in Redis to ensure exactly-once processing.
- 📤 Streams data into a Redpanda topic named "sms."
- 💾 Stores the data in ClickHouse for high-speed analytics.
- 📊 Visualizes the data with Superset, backed by MySQL for metadata storage.
- 🐳 Runs everything in Docker for easy setup and scalability.

The pipeline is lightweight, scalable, and designed for real-time data processing, making it ideal for analytics, reporting, and monitoring use cases. 🌟

## Prerequisites 📋

Before we start, ensure you have:
- **Docker** and **Docker Compose** installed on your machine. [Install Docker](https://docs.docker.com/get-docker/)
- Basic familiarity with command-line tools and YAML configuration.
- An FTP server with sample `.log.gz` files for testing (or mock data).
- A code editor (e.g., VS Code) for editing configuration files.

## Step 1: Understanding the Architecture 🏗️

The pipeline consists of several components, each with a specific role:
- **Redpanda Connect**: A lightweight streaming service that reads files from the FTP server, decompresses them, and sends data to a Redpanda topic. It uses Redis to track processed files, ensuring no duplicates.
- **Redpanda**: A Kafka-compatible streaming platform that hosts the "sms" topic for real-time data.
- **Redis**: A fast key/value store that prevents reprocessing of files and ensures exactly-once semantics.
- **ClickHouse**: A column-oriented database for storing and querying large datasets with blazing speed.
- **Superset**: A visualization tool for creating interactive dashboards from ClickHouse data.
- **MySQL**: Stores Superset’s metadata, such as dashboard configurations.
- **Docker**: Runs all services in containers for consistency and portability.

The data flow is simple: FTP → Redpanda Connect → Redpanda → ClickHouse → Superset, with Redis ensuring reliability and MySQL supporting Superset. 🔗

## Step 2: Setting Up the Project Directory 📁

1. Create a project directory (e.g., `data-pipeline`).
2. Inside it, create a `config` folder for configuration files.
3. Save the following files (provided below) in the appropriate locations:
   - `docker-compose.yml` in the root directory.
   - `config/connect-config-ftp.yaml` for Redpanda Connect.
   - `config/redis.conf` for Redis.
   - `config/remove_default_user.yaml` for ClickHouse.
   - `config/superset_config.py` for Superset.

## Step 3: Configuring the Docker Compose File 🐳

The `docker-compose.yml` file defines all services. Copy the following into `docker-compose.yml`:

```yaml
version: "3.7"
services:
  clickhouse:
    image: clickhouse/clickhouse-server:latest
    container_name: clickhouse-server
    hostname: clickhouse-server
    ports:
      - 8123:8123
      - 9000:9000
    volumes:
      - ./db:/var/lib/clickhouse 
      - ./config/remove_default_user.yaml:/etc/clickhouse-server/users.d/remove_default_user.yaml
    networks:
      - saman   
    restart: always   

  redpanda:
    image: redpandadata/redpanda:latest
    container_name: redpanda
    hostname: redpanda
    command:
      - redpanda
      - start
      - --node-id 0
      - --smp 2
      - --memory 2G
      - --overprovisioned
      - --rpc-addr redpanda:33145
      - --advertise-rpc-addr redpanda:33145
      - --kafka-addr internal://0.0.0.0:9092,external://0.0.0.0:19092
      - --advertise-kafka-addr internal://redpanda:9092,external://localhost:19092   
      - --pandaproxy-addr internal://0.0.0.0:8082,external://0.0.0.0:18082
      - --advertise-pandaproxy-addr internal://redpanda:8082,external://localhost:18082
    ports:
      - 9092:9092
      - 9644:9644
      - 8082:8082
    environment:
      - REDPANDA_NODE_ID=1
      - REDPANDA_LISTENERS="EXTERNAL://localhost:9092,INTERNAL://0.0.0.0:9092"
      - REDPANDA_KAFKA_ADVERTISED_LISTENERS="EXTERNAL://localhost:9092,INTERNAL://redpanda:9092"
    volumes:
      - ./redpanda-data:/var/lib/redpanda  
    networks:
      - saman
    restart: always  

  redpanda-connect:
    image: redpandadata/connect
    container_name: redpanda-connect
    hostname: redpanda-connect
    environment:
      CONNECT_BOOTSTRAP_SERVERS: 'redpanda:9092'
      CONNECT_REST_ADVERTISED_HOST_NAME: 'connect'
      CONNECT_GROUP_ID: 1
      CONNECT_CONFIG_STORAGE_TOPIC: connect_configs
      CONNECT_STATUS_STORAGE_TOPIC: connect_statuses
      CONNECT_OFFSET_STORAGE_TOPIC: connect_offsets
      CONNECT_KEY_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      CONNECT_VALUE_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR: '1'
      CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR: '1'
      CONNECT_STATUS_STORAGE_REPLICATION_FACTOR: '1' 
    ports:
      - 8083:8083 
    volumes:
      - ./config/connect-config-ftp.yaml:/connect.yaml
    depends_on:
      - redpanda
      - redis
    networks:
      - saman 
    restart: always   

  redpanda_console:
    image: redpandadata/console:latest
    container_name: redpanda_console
    hostname: redpanda_console
    ports:
      - 8080:8080
    environment:
      kafka_brokers: redpanda:9092
    depends_on:
      - redpanda
    networks:
      - saman 
    restart: always   

  superset:
    image: apache/superset:latest
    container_name: superset
    hostname: superset
    ports:
      - 8088:8088
    environment:
      - SQLALCHEMY_DATABASE_URI=mysql://superset_user:superset@mysql:3306/superset
    volumes:
      - superset_home:/app/superset
      - ./config/superset_config.py:/app/pythonpath/superset_config.py
    depends_on:
      - mysql     
    networks:
      - saman 
    restart: always       

  mysql:
    image: mysql:latest
    container_name: mysql
    hostname: mysql
    environment:
      MYSQL_ROOT_PASSWORD: superset
      MYSQL_DATABASE: superset
      MYSQL_USER: superset_user
      MYSQL_PASSWORD: superset
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - 3306:3306
    networks:
      - saman   
    restart: always    

  redis:
    image: redis:latest
    container_name: redis
    hostname: redis
    ports:
      - 6379:6379
    volumes:
      - ./redis_data:/data
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - saman  

volumes:
  superset_home:
  mysql_data:
networks:
  saman:     
    driver: bridge
```

> **Note**: Replace `Your Ip Server` in the `redpanda` service’s environment variables with your server’s IP or leave as `localhost` for local testing.

## Step 4: Configuring Redpanda Connect 📡

Redpanda Connect reads files from the FTP server and streams them to the "sms" topic. Create `config/connect-config-ftp.yaml` with the following content:

```yaml
cache_resources:
  - label: red
    redis:
      url: redis://redis:6379

input:
  label: "ftp_input"
  sftp:
    address: "X.X.X.X:22"
    credentials:
      username: "XXXX"
      password: "XXXX"    
    paths:
      - "./BI/*.log.gz"
    scanner:
      decompress:
        algorithm: "gzip"
        into:
          csv:
            custom_delimiter: ";"
            parse_header_row: false
            lazy_quotes: false
            continue_on_error: false        
    auto_replay_nacks: true
    delete_on_finish: false
    watcher:
      enabled: true
      minimum_age: 1m
      poll_interval: 1s
      cache: red
pipeline:
  threads: 4 
  processors:
    - bloblang: |
        root = {
          "ETL_TIME": now().ts_format("2006-01-02 15:04:05.999999", "Asia/Tehran"),
          "Col_1": this.0,
          "Col_2": this.1,
          "Col_3": this.2,
          "Col_4": this.3,
          "Col_5": this.4,
          "Col_6": this.5,
          "Col_7": this.6
        }
output:
  broker:
    pattern: fan_out
    outputs:
      - kafka:
          addresses:
            - redpanda:9092
          topic: sms
          max_in_flight: 5
          client_id: redpanda_connect
          compression: snappy
```

> **Important**: Replace `X.X.X.X:22`, `XXXX` (username), and `XXXX` (password) with your FTP server’s details. Ensure the `paths` field matches your FTP directory structure.

This configuration:
- Connects to Redis to track processed files.
- Reads `.log.gz` files from the FTP server, decompresses them, and parses them as CSV with a semicolon delimiter.
- Maps the CSV columns to a JSON structure with an `ETL_TIME` field.
- Sends the data to the "sms" topic in Redpanda.

## Step 5: Configuring Redis ⚡

Redis ensures exactly-once processing by storing the names of processed files. Create `config/redis.conf` with:

```
appendonly yes
appendfsync everysec
```

This enables persistent storage with updates synced every second.

## Step 6: Configuring ClickHouse 📈

ClickHouse stores the streamed data for analytics. To secure it, remove the default user. Create `config/remove_default_user.yaml`:

```yaml
users:
  default:
    "@remove": remove
```

Later, you’ll create a new admin user.

## Step 7: Configuring Superset 📊

Superset needs a configuration file for its database connection. Create `config/superset_config.py`:

```python
SECRET_KEY = 'Ly048vj1TXU9YSLTpOLl0wfY6EgNXCUv7VJiwoc5xZfJWlAsq1L2M+fV'
SQLALCHEMY_DATABASE_URI='mysql://superset_user:superset@mysql:3306/superset'

# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = True
# Add endpoints that need to be exempt from CSRF protection
WTF_CSRF_EXEMPT_LIST = []
# A CSRF token that expires in 1 year
WTF_CSRF_TIME_LIMIT = 60 * 60 * 24 * 365

FEATURE_FLAGS = {"ALERT_REPORTS": True, "DASHBOARD_RBAC": True}
```

## Step 8: Launching the Pipeline 🚀

1. In the project directory, run:
   ```bash
   docker compose up -d
   ```
   This starts all services: Redpanda, ClickHouse, Redis, MySQL, Superset, and Redpanda Connect.

2. Verify services are running:
   ```bash
   docker ps
   ```

## Step 9: Setting Up Superset 🖼️

Initialize Superset’s database and create an admin user:

```bash
docker-compose exec superset superset db upgrade
docker-compose exec superset superset init
docker-compose exec superset superset fab create-admin --username admin --firstname Superset --lastname Admin --email admin@example.com --password ch@ngeme
```

Access Superset at `http://localhost:8088` (login with `admin`/`ch@ngeme`).

## Step 10: Configuring ClickHouse Users 🔒

1. Access the ClickHouse container:
   ```bash
   docker exec -it clickhouse-server bash
   ```

2. Install `nano` for editing:
   ```bash
   apt-get update
   apt-get install nano
   ```

3. Edit `/etc/clickhouse-server/users.xml` to enable access management:
   ```bash
   nano /etc/clickhouse-server/users.xml
   ```
   Add:
   ```xml
   <access_management>1</access_management>
   <named_collection_control>1</named_collection_control>
   <show_named_collections>1</show_named_collections>
   <show_named_collections_secrets>1</show_named_collections_secrets>
   ```

4. Connect to ClickHouse and create an admin user:
   ```bash
   clickhouse-client
   ```
   Run:
   ```sql
   CREATE USER 'administrator' IDENTIFIED BY 'adminpass';
   GRANT ALL ON *.* TO administrator WITH GRANT OPTION;
   ```

5. Exit the container and restart ClickHouse:
   ```bash
   docker compose up -d
   ```

## Step 11: Creating ClickHouse Tables 📋

Create tables to store and process the "sms" topic data. Connect to ClickHouse:
```bash
docker exec -it clickhouse-server clickhouse-client
```

Run:
```sql
CREATE TABLE default.SMS
(
    `ETL_TIME` String,
    `Col_1` DateTime64(3),
    `Col_2` String,
    `Col_3` DateTime64(3),
    `Col_4` Int32,
    `Col_5` Int32,
    `Col_6` Int32,
    `Col_7` Int32
)
ENGINE = MergeTree
PARTITION BY toYYYYMMDD(Col_1)
ORDER BY Col_1
SETTINGS index_granularity = 8192;

CREATE TABLE default.Redpanda_SMS
(
    `ETL_TIME` String,
    `Col_1` DateTime64(3),
    `Col_2` String,
    `Col_3` DateTime64(3),
    `Col_4` Int32,
    `Col_5` Int32,
    `Col_6` Int32,
    `Col_7` Int32
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list = 'sms',
         kafka_group_name = 'clickhouse',
         kafka_format = 'JSONEachRow',
         kafka_num_consumers = 1,
         kafka_skip_broken_messages = 1;

CREATE MATERIALIZED VIEW default.MV_SMS TO default.SMS
(
    `ETL_TIME` String,
    `Col_1` DateTime64(3),
    `Col_2` String,
    `Col_3` DateTime64(3),
    `Col_4` Int32,
    `Col_5` Int32,
    `Col_6` Int32,
    `Col_7` Int32
)
AS SELECT
    ETL_TIME,
    Col_1,
    Col_2,
    Col_3,
    Col_4,
    Col_5,
    Col_6,
    Col_7
FROM default.Redpanda_SMS
SETTINGS stream_like_engine_allow_direct_select = 1;
```

These tables:
- `SMS`: Stores the final data.
- `Redpanda_SMS`: Reads from the "sms" topic.
- `MV_SMS`: Materialized view to transfer data from `Redpanda_SMS` to `SMS`.

## Step 12: Monitoring with Redpanda Console 👀

Access Redpanda Console at `http://localhost:8080` to monitor topics, messages, and connectors. Verify that the "sms" topic is receiving data from the FTP server.

## Step 13: Creating Dashboards in Superset 📈

1. In Superset, add a ClickHouse database:
   - Go to **Settings > Database Connections > + Database**.
   - Select **ClickHouse** and use:
     ```
     clickhouse://administrator:adminpass@clickhouse-server:8123/default
     ```

2. Create a dataset from the `SMS` table.
3. Build charts (e.g., line charts, bar charts) and add them to a dashboard.

## Step 14: Testing the Pipeline ✅

1. Upload a sample `.log.gz` file to your FTP server’s `./BI/` directory.
2. Check Redpanda Console to confirm data in the "sms" topic.
3. Query the `SMS` table in ClickHouse:
   ```sql
   SELECT * FROM default.SMS LIMIT 10;
   ```
4. Verify the data appears in Superset dashboards.

## Troubleshooting Tips 🛠️

- **Redpanda Connect fails to read FTP files**: Check FTP credentials and file paths in `connect-config-ftp.yaml`.
- **ClickHouse user issues**: Ensure `users.xml` is updated and the `administrator` user is created.
- **Superset errors**: Verify MySQL is running and the `SQLALCHEMY_DATABASE_URI` is correct.
- **Docker issues**: Run `docker compose logs <service>` to debug.

## Conclusion 🎉

Congratulations! You’ve built a real-time data pipeline that processes FTP data, streams it through Redpanda, stores it in ClickHouse, and visualizes it with Superset. This setup is scalable, fault-tolerant, and ready for production use. Try experimenting with different data sources or dashboard designs to take it further! 🚀

Feel free to share your pipeline on Medium or GitHub, and let me know in the comments if you have questions or improvements! 😊
