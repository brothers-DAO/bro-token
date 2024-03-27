# BRO Token API

## Module: `bro`

Standard **fungible-v2** module with usual API.

## Module `bro-registry`

A simple decentralized registry to store on chain "TG account" -> BRO account mapping.
Encrypted by a password only known by the bot. "TG accounts" never appears unencrypted in transactions.

#### encrypt-tg-account
`tg-account` *string* `password` *string* -> *string*

Reference function to encrypt a TG account.
Must only be used in local, **never** on chain to preserve privacy.

JS Equivalent:
```js
import {hash} from '@kadena/cryptography-utils';

const encrypt = (x, password) => "enc_" + hash(x+password);
```

```pact
(encrypt-tg-account "@alice" "My-Password")
  >  enc_EI3cFxvCQlMHHwFgxupYkDRWX_SCYL4MyrCvSdqrKus
```

#### register
`tg-account-enc` *string* `bro-account-b64` *string* -> string

Register a TG account for future holdings check and tipping. Only accessible
by the bot.

To preserve privacy:
- `tg-account-enc` must be encrypted

- `bro-account-b64` must be a base64 string

Must be signed with `NS_BRO.bot` with the cap `(BOT-OPERATOR)` in scope.

```pact
(register "enc_EI3cFxvCQlMHHwFgxupYkDRWX_SCYL4MyrCvSdqrKus"
          "azozMTQ2NDM5YzcyZTFmZjEzNzUwZWIwYWJkOTg5MWI5MGViMjhmZjAxMTI4NGVjMzM3YWQwMzdlM2VjMjY0YWZk")
```

#### unregister
`tg-account-enc` *string*  -> *string*

Un-Register a TG. Only accessible by the bot.

Must be signed with `NS_BRO.bot` with the cap `(BOT-OPERATOR)` in scope.

```pact
(unregister "enc_EI3cFxvCQlMHHwFgxupYkDRWX_SCYL4MyrCvSdqrKus")
```


## Module `pre-sales`

Module to handle the pre-sales phase.

#### reserve-batch
``account`` *string* -> *string*

Reserve a batch for a Kadena account for being bought during phase 0 or 1.

The objective is to allow current Brothers have a priority during pre-sales.

This purchase will only validated by calling before `(buy)` before the end of Phase 1.

Only accessible by administrator.

Must be signed with `NS_BRO.sales-operator` with the cap `(SALES-OPERATOR)` in scope.


```pact
(reserve-batch "k:3146439c72e1ff13750eb0abd9891b90eb28ff011284ec337ad037e3ec264afd")
```

#### buy
``account`` *string*  ``guard``-> *string*

But a batch for an account. Guard is used to create the $BRO account.

Must be signed by the user account with the cap `(coin.TRANSFER account SALES-ACCOUNT 10.0)` in scope.

```pact
(buy "k:3146439c72e1ff13750eb0abd9891b90eb28ff011284ec337ad037e3ec264afd" (read-keyset 'ks))
```


#### end-sales
->

To be called by the admin only once after the pre-sales have ended, to launch the token

Must be signed with `NS_BRO.sales-operator` with the cap `(SALES-OPERATOR)` in scope.

### Other utility functions and consts

#### Const SALES-ACCOUNT
*string*

The sales account where tokens must be paid in KDA. For being used by the cap of the `buy` function

#### in-phase-0
-> *bool*

Returns true if we are in pre-sales phase 0

#### in-phase-1
-> *bool*

Returns true if we are in pre-sales phase 1

#### in-phase-2
-> *bool*

Returns true if we are in pre-sales phase 2

#### available-for-free-sales
-> *integer*

Returns the number of available batches for being immediately bought.


## Module `bro-treasury`

#### tip
`tg-account-enc` *string*  -> *string*

Tip a TG account from the treasury. The TG account has to be registered in the registry before.

Must be signed with `NS_BRO.bot` with the cap `(BOT-OPERATOR)` in scope.

```pact
(tip "enc_EI3cFxvCQlMHHwFgxupYkDRWX_SCYL4MyrCvSdqrKus")
```

#### gather-rewards
-> *string*

Run the "gather DEX rewards procedure":
- Remove the rewards parts of DEX liquidity
- Swaps KDA to $BRO
- Send the $BRO to the treasury account

```pact
(gather-rewards)
```

### Other utility functions

#### liquidity-to-remove
-> *decimal*

Has to be called by the BOT before trying to gather rewards.

The result should be no less than a specified amount (or at least positive).
