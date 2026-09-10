"""Run the Jaffle Shop dbt pipeline every day at 8:00 PM Cairo time."""

from __future__ import annotations

from datetime import timedelta
from pathlib import Path

import pendulum
from airflow import DAG

try:
    # Airflow 3.x (and Airflow 2.x with the standard provider installed).
    from airflow.providers.standard.operators.bash import BashOperator
except ImportError:
    # Compatibility with Airflow 2.x.
    from airflow.operators.bash import BashOperator


PROJECT_DIR = Path(__file__).resolve().parents[1]
CAIRO_TIMEZONE = pendulum.timezone("Africa/Cairo")


with DAG(
    dag_id="jaffle_shop_daily",
    description="Build and test the Jaffle Shop dbt project every day.",
    schedule="0 20 * * *",
    start_date=pendulum.datetime(2024, 1, 1, tz=CAIRO_TIMEZONE),
    catchup=False,
    max_active_runs=1,
    default_args={
        "owner": "data-engineering",
        "retries": 2,
        "retry_delay": timedelta(minutes=5),
    },
    tags=["dbt", "jaffle-shop"],
) as dag:
    dbt_build = BashOperator(
        task_id="dbt_build",
        append_env=True,
        env={"DEFAULT_DBT_PROJECT_DIR": str(PROJECT_DIR)},
        bash_command=(
            "set -euo pipefail\n"
            'DBT_PROJECT_DIR="${DBT_PROJECT_DIR:-$DEFAULT_DBT_PROJECT_DIR}"\n'
            'DBT_PROFILES_DIR="${DBT_PROFILES_DIR:-$HOME/.dbt}"\n'
            'cd "$DBT_PROJECT_DIR"\n'
            'dbt deps --project-dir "$DBT_PROJECT_DIR"\n'
            'dbt build --project-dir "$DBT_PROJECT_DIR" '
            '--profiles-dir "$DBT_PROFILES_DIR"'
        ),
    )
