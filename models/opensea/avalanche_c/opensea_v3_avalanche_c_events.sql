{{ config(
    schema = 'opensea_v3_avalanche_c',
    alias = 'events',
    
    materialized = 'incremental',
    file_format = 'delta',
    incremental_strategy = 'merge',
    unique_key = ['tx_hash', 'evt_index', 'nft_contract_address', 'token_id', 'sub_type', 'sub_idx']
    )
}}

WITH fee_wallets as (
    select wallet_address, wallet_name from (
    values (0x0000a26b00c1f0df003000390027140000faa719,'opensea')
    ) as foo(wallet_address, wallet_name)
)
, trades as (
    {{ seaport_v3_trades(
     blockchain = 'avalanche_c'
     ,source_transactions = source('avalanche_c','transactions')
     ,Seaport_evt_OrderFulfilled = source('seaport_avalanche_c','Seaport_evt_OrderFulfilled')
     ,Seaport_call_matchAdvancedOrders = source('seaport_avalanche_c','Seaport_call_matchAdvancedOrders')
     ,Seaport_call_matchOrders = source('seaport_avalanche_c','Seaport_call_matchOrders')
     ,fee_wallet_list_cte = 'fee_wallets'
     ,native_token_address = '0x0000000000000000000000000000000000000000'
     ,alternative_token_address = '0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7'
     ,native_token_symbol = 'AVAX'
     ,start_date = '2022-09-06'
    )
  }} 
)

select *
from trades
where (    fee_wallet_name = 'opensea'
           or right_hash = 0x360c6ebe
         )