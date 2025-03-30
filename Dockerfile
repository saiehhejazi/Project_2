# Use the official Apache Superset image as the base
FROM apache/superset:latest

USER root

# Install the ClickHouse client and Python ClickHouse library and Mysql and MsSQL
RUN apt-get update && \
    apt-get install -y \
    clickhouse-client \
    libmariadb-dev \
    pkg-config \
    build-essential \
    && pip install apache-superset clickhouse_connect pymssql sqlalchemy mysqlclient

# Set environment variables
ENV SUPERSET_HOME=/app/superset
ENV TZ=Asia/Tehran
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Switch back to the default user
USER superset


# Set the entrypoint to start the Superset server
CMD ["gunicorn", "--bind", "0.0.0.0:8088", "--workers", "3", "--timeout", "60", "--limit-request-line", "0", "--limit-request-field_size", "0", "superset.app:create_app()"]

