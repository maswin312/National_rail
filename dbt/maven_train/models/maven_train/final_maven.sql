{{
    config(
        materialized="table",
        partition_by={
            "field": "date_of_journey",
            "data_type": "timestamp",
            "granularity": "day",
        },
        cluster_by=[
            "departure_station",
            "arrival_destination",
            "journey_status",
            "payment_method",
        ],
    )
}}


with
    final_maven as (select * from {{ source("maven", "raw_maven_data") }}),

    base as (
        select
            cast(price as int64) as price,
            railcard,
            ticket_type,
            arrival_time,
            ticket_class,
            purchase_type,
            journey_status,
            payment_method,
            refund_request,
            transaction_id,
            case
                when reason_for_delay = 'Weather Conditions'
                then 'Weather'
                when reason_for_delay = 'Signal failure'
                then 'Signal Failure'
                when reason_for_delay = 'Staffing'
                then 'Staff Shortage'
                else reason_for_delay
            end as reason_for_delay,
            departure_station,
            actual_arrival_time,
            arrival_destination,
            concat(departure_station, " - ", arrival_destination) as route,
            timestamp(
                (concat(date_of_journey, " ", departure_time))
            ) as date_of_journey,
            timestamp((concat(date_of_journey, " ", arrival_time))) as date_of_arrival,
            timestamp(
                (concat(date_of_journey, " ", actual_arrival_time))
            ) as date_of_actual_arrival_time,
            timestamp(
                (concat(date_of_purchase, " ", time_of_purchase))
            ) as date_of_purchase
        from final_maven
    ),

    base2 as (
        select
            * except (date_of_arrival, date_of_actual_arrival_time),
            case
                when date_of_journey > date_of_arrival
                then timestamp_add(date_of_arrival, interval 24 hour)
                else date_of_arrival
            end as date_of_arrival,
            case
                when date_of_journey > date_of_actual_arrival_time
                then timestamp_add(date_of_actual_arrival_time, interval 24 hour)
                else date_of_actual_arrival_time
            end as date_of_actual_arrival_time
        from base
    ),

    base3 as (
        select
            *,
            (
                unix_seconds(date_of_actual_arrival_time)
                - unix_seconds(date_of_arrival)
            ) as delayed_time
        from base2
    )

select
    * except (journey_status),
    {{ dbt_utils.generate_surrogate_key(["route", "date_of_journey"]) }} as trips_id,
    case when delayed_time = 0 then 'On Time' else journey_status end as journey_status,
    case
        when (delayed_time / 60) between 1 and 15
        then '1 - 15 Mins'
        when (delayed_time / 60) between 16 and 30
        then '16 - 30 Mins'
        when (delayed_time / 60) between 31 and 45
        then '31 - 45 Mins'
        when (delayed_time / 60) between 46 and 60
        then '46 - 60 Mins'
        when (delayed_time / 60) > 60
        then ' > 60 Mins'
        else null
    end as delayed_duration
from base3
