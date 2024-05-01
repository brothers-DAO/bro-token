(namespace "BRO_NS")

include(bro-treasury.pact)dnl
"Module loaded"
(enforce (bro.is-supply-chain) "Only on supply chain")

ifdef(`__INIT__',dnl
(create-table liquidity-management)
(create-table tips-counters)
(init)
)
