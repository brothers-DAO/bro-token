(use free.util-chain-data [chain-id])
(namespace "BRO_NS")

include(bro-token.pact)dnl
(BRO_NS.bro.enforce-is-deployed-chain (chain-id))
"Module loaded"



ifdef(`__INIT__',dnl
(create-table user-accounts-table)
(create-table init-table)
ifdef(`__IS_INIT_CHAIN__', (DEX_NS.exchange.create-pair coin BRO_NS.bro ""))
)
