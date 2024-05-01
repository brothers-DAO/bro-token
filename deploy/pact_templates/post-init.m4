ifdef(`__IS_INIT_CHAIN__',dnl
(enforce (BRO_NS.bro.is-supply-chain) "Only on supply chain")
(BRO_NS.bro.init-supply
  BRO_NS.bro-pre-sales.BRO-RESERVE-ACCOUNT BRO_NS.bro-pre-sales.BRO-RESERVE-GUARD
  BRO_NS.bro-treasury.TREASURY-ACCOUNT     BRO_NS.bro-treasury.TREASURY-GUARD
  BRO_NS.bro-treasury.LIQUIDITY-ACCOUNT    BRO_NS.bro-treasury.LIQUIDITY-GUARD)
,
(BRO_NS.bro.init))
