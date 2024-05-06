# $BRO Deployment Checklist

## Checks

### Contract bro-token

Check deployed chains
Check initial chain


### Contract bro-pre-sales

Check pre-sales dates

Update creationTime in launch.tkpl accordingly to launch date.

### Namespaces

Modify namespace in testnet.yaml or mainnet.yaml
Modify namespace in Makefile

### Ecko DEX

Check namespace in Makefile


### Keys
Check all keys in testnet.yaml and tkpl/init.tkpl

### Data file
Check data file in Makefile

## Init namespaces and keys

make init

kda sign tx_init_*.yaml -k ....

kda local tx_init_0.json
kda local tx_init_2.json
kda send tx_init_*.json


## Contracts deployment
Check INIT and IS_INIT_CHAIN variables in Makefile
INIT must be uncommented for first deployment.
IS_INIT_CHAIN must be uncommented if we are working on main chain.

Set the chain in testnet/mainnet.yaml

run: make all
Then sign all the tx_bro...json

Deploy first bro-registry and bro-token.
Then bro-treasury
Then bro-presales


### Bro token
Check the file .pact/bro-token.pact.
If first deployment, it should contain table creations
If deployed on the main chain, it should contain Ecko registration.
