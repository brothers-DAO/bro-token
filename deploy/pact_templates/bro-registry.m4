(namespace "BRO_NS")

include(bro-registry.pact)dnl
"Module loaded"
(enforce (bro.is-supply-chain) "Only on supply chain")

ifdef(`__INIT__',dnl
(create-table accounts)
(create-table account-locked-table)
)
