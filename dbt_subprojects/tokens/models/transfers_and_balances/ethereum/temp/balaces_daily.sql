{{ config(
        schema = 'temp',
        alias = 'balances_daily',
        materialized = 'table'
        )
}}


select * from {{ref('tokens_ethereum_balances_daily_agg')}}
where day > now() - interval '30' day