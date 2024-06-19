from pendulum import datetime
from airflow.decorators import dag
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

from cosmos import DbtDag
from cosmos.operators import DbtDocsOperator
from cosmos.config import RenderConfig

from dbt_config import project_config, profile_config  # type:ignore


# Define the ELT DAG
@dag(
    dag_id="elt_dag",
    start_date=datetime(2024, 6, 1),
    schedule="@daily",
    tags=["airbyte", "dbt", "bigquery", "maven"],
    catchup=False,
)
def extract_and_transform():
    """
    Runs the connection "Faker to BigQuery" on Airbyte and then triggers the dbt DAG.
    """
    # Airbyte sync task
    extract_data = AirbyteTriggerSyncOperator(
        task_id="trigger_airbyte_sheets_to_bigquery",
        airbyte_conn_id="airbyte_connection",
        connection_id="8c0bfb7d-eb6c-4429-a775-91f2c24bf08d", # Update with your Airbyte connection ID
        asynchronous=False,
        timeout=3600,
        wait_seconds=3
    )

    # Trigger for dbt DAG
    trigger_dbt_dag = TriggerDagRunOperator(
        task_id="trigger_dbt_dag",
        trigger_dag_id="dbt_maven",
        wait_for_completion=True,
        poke_interval=30,
    )


    # Set the order of tasks
    extract_data >> trigger_dbt_dag 

# Instantiate the ELT DAG
extract_and_transform_dag = extract_and_transform()

# Define the dbt DAG using DbtDag from the cosmos library
dbt_cosmos_dag = DbtDag(
    dag_id="dbt_maven",
    start_date=datetime(2024, 6, 1),
    tags=["dbt", "maven"],
    catchup=False,
    project_config=project_config,
    profile_config=profile_config,
    render_config=RenderConfig(select=["path:models/maven_train"]),
)

# Instantiate the dbt DAG
dbt_cosmos_dag