ARG AIRFLOW_VERSION=3.3.1
FROM apache/airflow:${AIRFLOW_VERSION}-python3.12

# Keep dbt in its own virtual environment so its dependencies cannot alter
# the dependencies pinned in the official Airflow image.
RUN python -m venv /opt/airflow/dbt-venv \
    && /opt/airflow/dbt-venv/bin/pip install --no-cache-dir \
        "dbt-snowflake==1.12.0"

ENV PATH="/opt/airflow/dbt-venv/bin:${PATH}"

