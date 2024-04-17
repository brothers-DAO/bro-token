ifdef(`__IS_INIT_CHAIN__',dnl
(BRO_NS.bro.init-supply
  BRO_NS.bro-pre-sales.BRO-RESERVE-ACCOUNT BRO_NS.bro-pre-sales.BRO-RESERVE-GUARD
  BRO_NS.bro-treasury.TREASURY-ACCOUNT     BRO_NS.bro-treasury.TREASURY-GUARD
  BRO_NS.bro-treasury.LIQUIDITY-ACCOUNT    BRO_NS.bro-treasury.LIQUIDITY-GUARD)
,
(BRO_NS.bro.init))
