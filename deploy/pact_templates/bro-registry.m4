(namespace "BRO_NS")

include(bro-registry.pact)dnl
"Module loaded"

ifdef(`__INIT__',dnl
(create-table accounts)
(create-table account-locked-table)
)
