(namespace "BRO_NS")

include(bro-treasury.pact)dnl
"Module loaded"

ifdef(`__INIT__',dnl
(create-table liquidity-management)
(create-table tips-counters)
(init)
)
