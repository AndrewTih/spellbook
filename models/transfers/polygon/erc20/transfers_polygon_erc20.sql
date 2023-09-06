{{ config(
    tags=['dunesql'],
    materialized = 'incremental',
    file_format = 'delta',
    incremental_strategy = 'merge',
    unique_key = ['transfer_type', 'evt_tx_hash', 'evt_index', 'wallet_address'], 
    alias = alias('erc20'),
    post_hook='{{ expose_spells(\'["polygon"]\',
                                    "sector",
                                    "transfers",
                                    \'["soispoke", "dot2dotseurat", "tschubotz", "hosuke", "Henrystats"]\') }}'
    )
}}
WITH 

erc20_transfers  as (
        SELECT 
            'receive' as transfer_type, 
            evt_tx_hash,
            evt_index, 
            evt_block_time,
            to as wallet_address, 
            contract_address as token_address,
            CAST(value as double) as amount_raw
        FROM 
        {{ source('erc20_polygon', 'evt_transfer') }}
        {% if is_incremental() %}
            WHERE evt_block_time >= date_trunc('day', now() - interval '7' Day)
        {% endif %}

        UNION ALL 

        SELECT 
            'send' as transfer_type, 
            evt_tx_hash,
            evt_index, 
            evt_block_time,
            "from" as wallet_address, 
            contract_address as token_address,
            -CAST(value as double) as amount_raw
        FROM 
        {{ source('erc20_polygon', 'evt_transfer') }}
        {% if is_incremental() %}
            WHERE evt_block_time >= date_trunc('day', now() - interval '7' Day)
        {% endif %}
),

wmatic_events as (
        SELECT 
            'deposit' as transfer_type, 
            evt_tx_hash, 
            evt_index, 
            evt_block_time,
            dst as wallet_address, 
            contract_address as token_address, 
            CAST(wad as double)as amount_raw
        FROM 
        {{ source('mahadao_polygon', 'wmatic_evt_deposit') }}
        {% if is_incremental() %}
        WHERE evt_block_time >= date_trunc('day', now() - interval '7' Day)
        {% endif %}

        UNION ALL 

        SELECT 
            'withdraw' as transfer_type, 
            evt_tx_hash, 
            evt_index, 
            evt_block_time,
            src as wallet_address, 
            contract_address as token_address, 
            -CAST(wad as double)as amount_raw
        FROM 
        {{ source('mahadao_polygon', 'wmatic_evt_withdrawal') }}
        {% if is_incremental() %}
        WHERE evt_block_time >= date_trunc('day', now() - interval '7' Day)
        {% endif %}
)
SELECT
    'polygon' as blockchain, 
    transfer_type,
    evt_tx_hash, 
    evt_index,
    evt_block_time,
    wallet_address, 
    token_address, 
    amount_raw
FROM 
erc20_transfers

UNION ALL 

SELECT 
    'polygon' as blockchain, 
    transfer_type,
    evt_tx_hash, 
    evt_index,
    evt_block_time,
    wallet_address, 
    token_address, 
    amount_raw
FROM 
wmatic_events