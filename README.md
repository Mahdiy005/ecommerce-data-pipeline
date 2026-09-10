# 🥪 The Jaffle Shop 🦘

_powered by the dbt Fusion engine_

Welcome! This is a sandbox project for exploring the basic functionality of Fusion. It's based on a fictional restaurant called the Jaffle Shop that serves [jaffles](https://en.wikipedia.org/wiki/Pie_iron).

To get started:
1. Set up your database connection in `~/.dbt/profiles.yml`. If you got here by running `dbt init`, you should already be good to go.
2. Run `dbt build`. That's it!

> [!NOTE]
> If you're brand-new to dbt, we recommend starting with the [dbt Learn](https://learn.getdbt.com/) platform. It's a free, interactive way to learn dbt, and it's a great way to get started if you're new to the tool.

## Airflow schedule

The DAG in `dags/jaffle_shop_daily.py` runs `dbt deps` followed by `dbt build`
every day at 8:00 PM in the `Africa/Cairo` timezone. It has catchup disabled,
allows only one active run, and retries failed runs twice at five-minute intervals.

Mount this repository where the Airflow worker can access it, and put the DAG file
in Airflow's DAG folder. If only the `dags` directory is copied, set
`DBT_PROJECT_DIR` on the worker to this dbt project's directory. The task uses the
standard dbt profile directory (`$HOME/.dbt`) by default; override it with
`DBT_PROFILES_DIR` when needed. The worker environment must include Airflow,
`pendulum`, dbt, the project's database adapter, and access to the target database.

## Run with Docker

Docker Desktop must be running with at least 4 GB of memory available. From
PowerShell in this project directory, run:

```powershell
.\start-airflow.ps1
```

On its first run, the script creates an ignored `.env` file and generates the
internal PostgreSQL and Airflow secrets. Open `.env`, replace every `change-me`
value with your Snowflake connection values and a strong Airflow admin password,
then run the script again. The first image build can take several minutes.

Open <http://localhost:8080>, sign in using `AIRFLOW_ADMIN_USERNAME` and
`AIRFLOW_ADMIN_PASSWORD` from `.env`, and find the `jaffle_shop_daily` DAG. It is
enabled automatically and runs every day at 8:00 PM Cairo time. Use the play
button in the Airflow UI to test it immediately.

Useful commands:

```powershell
# Show container status and follow logs
docker compose ps
docker compose logs --follow airflow-scheduler

# Validate dbt from inside the same image used by Airflow
docker compose run --rm airflow-scheduler dbt debug

# Stop services while retaining the Airflow database and logs
.\stop-airflow.ps1

# Delete all Docker data and start from an empty Airflow database
docker compose down --volumes
```

The Compose stack uses PostgreSQL for Airflow metadata and named volumes for
state. The dbt profile reads Snowflake credentials only from the ignored `.env`
file; credentials are not included in the image or committed files. For a larger
or highly available deployment, use a managed Airflow service or the official
Airflow Helm chart instead of this single-host `LocalExecutor` setup.
