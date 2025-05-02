In this project, files stored on the FTP server are first extracted from their compressed form, then their content is read and placed into a topic called "sms". Additionally, to prevent reprocessing of files that have already been read, it is necessary to store the names of the read files somewhere. For this purpose, Redis database is used, ensuring that the data is also persistently stored on disk. All of these processes are carried out using a connector designed by Redpanda, named sftp.
The content of the topic is then stored in a table created in Clickhouse. 
To generate reports and dashboards based on this table, Superset is used. The metadata for Superset is stored in a MySQL database.
All of the above steps are performed using Docker.

**The following provides brief explanations about each of the services.**

 **Redpanda :** 
 
<img width="259" alt="Redpanda" src="https://github.com/user-attachments/assets/42eb3e8f-a0ee-4e6f-b269-f72745ca10eb" />

Redpanda (formerly Vectorized) is a data streaming platform developed using C++. It’s a high-performance alternative to Kafka that provides compatibility with the Kafka API and protocol. In fact, if you look at Redpanda’s website, you’ll get the feeling it’s a simple, cost-effective drop-in replacement for Kafka. Similar to Kafka, Redpanda is leveraged by businesses and developers for use cases like stream processing, real-time analytics, and event-driven architectures. 
Kafka is an established Java-based data streaming platform, with a large community and a robust ecosystem. Meanwhile, Redpanda is an emerging, Kafka-compatible tech written in C++, with an architecture designed for high performance and simplicity.


**Redis :**

Redis <img width="287" alt="Redis" src="https://github.com/user-attachments/assets/69fec47b-b078-43f8-b919-18b91214ba5e" />

is an open source data structure server. It belongs to the class of NoSQL databases known as key/value stores. Keys are unique identifiers, whose value can be one of the data types that Redis supports. These data types range from simple Strings, to Linked Lists, Sets and even Streams. Each data type has its own set of behaviours and commands associated with it.



**ClickHouse :**

![ClickHouse](https://github.com/user-attachments/assets/f511bd8a-3283-45b2-b607-5847290bfd2b)


ClickHouse is a highly scalable open source database management system (DBMS) that uses a column-oriented structure. It's designed for online analytical processing (OLAP) and is highly performant. ClickHouse can return processed results in real time in a fraction of a second. This makes it ideal for applications working with massive structured data sets: data analytics, complex data reports, data science computations...
ClickHouse is most praised for its exceptionally high performance. That performance comes from a sum of many factors:

*	Column-oriented data storage
*	Data compression
*	The vector computation engine
*	Approximated calculations
*	The use of physical sparse indices

But performance isn't the only benefit of ClickHouse. ClickHouse is more than a database, it's a sophisticated database management system that supports distributed query processing, partitioning, data replication and sharding. It's a highly scalable and reliable system capable of handling terabytes of data.
In fact, ClickHouse is designed to write huge amounts of data and simultaneously process a large number of reading requests. And you can conveniently use a declarative SQL-like query language.

**Superset :**

<img width="348" alt="Superset" src="https://github.com/user-attachments/assets/ca09e3f4-74a4-4aac-8911-bbde2831ecb1" />

 Superset is fast, lightweight, intuitive, and loaded with options that make it easy for users of all skill sets to explore and visualize their data, from simple line charts to highly detailed geospatial charts.




**It's time for the implementation:**

1-	Since all the services are implemented with Docker, it is necessary to install Docker and Docker Compose. Then, using the following command, all the services described above will be brought up:

docker compose up -d

2-	To fully install Superset, you should run the following commands:

 docker-compose exec superset superset db upgrade
 docker-compose exec superset superset init
 docker-compose exec superset superset fab create-admin --username admin --firstname Superset --lastname Admin --email admin@example.com --password ch@ngeme

The above commands will ensure that the necessary database for storing users, dashboards, and other data is created for Superset. Additionally, a user will be created with the specified details.

3-	When ClickHouse is installed, a default user named default is created by default. It is recommended to deactivate this user and create another one. To do this, follow these steps:

   docker exec -it clickhouse-server bash
   cd /etc/clcikhouse-server
   apt-get update
   apt install nano
   nano users.xml :
    (Add These commands ):
   <access_management>1</access_management>
   <named_collection_control>1</named_collection_control>
   <show_named_collections>1</show_named_collections>
   <show_named_collections_secrets>1</show_named_collections_secrets>

 According : https://clickhouse.com/docs/operations/access-rights#enabling-access- control

 After that, use clickhouse-client command :
 
   Use default database;
   CREATE USER 'administrator'    IDENTIFIED BY 'adminpass';
   GRANT ALL ON *.* TO administrator WITH GRANT OPTION;

Then edit docker-compose.yaml and uncomment :
 
  - ./config:/etc/clickhouse-server/users.d
    
And run “docker compose up -d “ again.

4-	One of the most important sections is the configuration related to redpanda-connect, which is located in the config folder  (connect-config-ftp.yaml). This section is used to connect to the FTP server and read files:

cache_resources:
  - label: red
    redis:
      url: redis://redis:6379

This section is used to store the names of the files that have been processed.

input:
  label: "ftp_input"
  sftp:
    address: "X.X.X.X:22"
    credentials:
      username: "XXXX"
      password: "XXXX"    
    paths:
      - "./Protei/3*.log.gz"

This section contains the connection details for the FTP server.

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

In this section, the format for reading the files is specified. Additionally, the files are first extracted from their compressed state and then read. It is important to note that the extracted files are never created on the FTP server; they reside in the server's memory and are deleted as soon as the task is completed.

pipeline:
  processors:
    - bloblang: |
        root = {
          "Col_1": this.0,
          "Col_2": this.1,
          "Col_3": this.2,
          "Col_4": this.3,
          "Col_5": this.4,
          "Col_6": this.5          
        }
This section specifies the mapping of the columns

output:
  broker:
    pattern: fan_out
    outputs:
      - kafka:
          addresses:
            - redpanda:9092
          topic: sms
          max_in_flight: 1
          client_id: redpanda_connect
          compression: snappy

Finally, we specify the output, which is that the read file should be placed in a topic named sms.

5-	In the config folder, in addition to the settings related to redpanda-connect, there are also configurations for Redis, ClickHouse, and Superset.


6-	Create These Tables in ClickHouse :

  CREATE TABLE default.SMS
  (
    `ETL_TIME` String,
    `Col_1` DateTime64(3),
    `Col_2` String,
    `Col_3` DateTime64(3),
    `Col_4` Int32,
    `Col_5` Int32,
    `Col_6` Int32
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
  `Col_6` Int32
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
    `Col_6` Int32
 )
 AS SELECT
    ETL_TIME,
    Col_1,
    Col_2,
    Col_3,
    Col_4,
    Col_5,
    Col_6
FROM default.Redpanda_SMS
SETTINGS stream_like_engine_allow_direct_select = 1;



