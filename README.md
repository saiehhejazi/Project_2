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

