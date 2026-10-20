FROM python:3.10-slim

# Install Java (Required for PySpark)
RUN apt-get update && \
    apt-get install -y default-jre procps && \
    rm -rf /var/lib/apt/lists/*

# Install PySpark and Pandas
RUN pip install --no-cache-dir pyspark==4.2.0 pandas==2.3.3

WORKDIR /app
COPY run_spark_sql.py /app/run_spark_sql.py

ENTRYPOINT ["python", "/app/run_spark_sql.py"]
