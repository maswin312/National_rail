FROM apache/airflow:2.9.2
USER airflow
RUN pip install apache-airflow-providers-airbyte[http] \
&& pip install apache-airflow-providers-airbyte \
&& pip install dbt-bigquery
