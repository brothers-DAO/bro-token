(use free.util-time [is-future])

(namespace "BRO_NS")

include(bro-pre-sales.pact)dnl
"Module loaded"
(enforce (bro.is-supply-chain) "Only on supply chain")

ifdef(`__INIT__',dnl
; Some sanity checks
(enforce (is-future NS_BRO.bro-pre-sales.PHASE-1-START) "Bad dates")
(enforce (is-future NS_BRO.bro-pre-sales.PHASE-2-START) "Bad dates")
(enforce (is-future NS_BRO.bro-pre-sales.END-OF-PRESALES) "Bad dates")

(create-table global-counters)
(create-table accounts-table)
(init)
)
