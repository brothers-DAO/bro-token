# $BRO Token: The Token of Kadena Brothers

## Token address

`n_582fed11af00dc626812cd7890bb88e72067f28c.bro`

## Main characteristics.

Low limited supply: **100.0 $BRO** in total

Public treasury will distribute slowly some $BRO to best contributors through tipping for KCP
(Kadena Culture Production)

The token has 12 decimals. The minimum usable amount is **0.000000000001** and is called a **Doug**.
An amount of **0.001** is called a **GiDoug**.

## Tokenomics

|                   |                                   |                                                |
| ----------------- | ----------------------------------|------------------------------------------------|
| Public Treasury   | 20.0 $BRO + Pre-sales unsold      | Used to tip 0.001 $BRO for KCP                 |
| DEX Liquidity     | 40.0 $BRO + Pre-sales income KDA  | DEX fees income transferred to public treasury |
| Pre-sales         | 40.0 $BRO                         | Distributed after pre-sales to holders         |
| **Total**         | **100.0 $BRO**                    |                                                |


## Pre-Sales

**100** Batches of **0.4 $BRO** each are available. Each batch is sold **10.0 KDA**

#### Pre-sales Phase 0 (until Date 2024-05-14T18:00:00Z)

Brothers have the possibility to reserve 1 Batch. The reservation is done with the governance rights.
The reservation is possible and must be paid until the end of Phase 1.

Only reserved batches can be bought.

#### Pre-sales Phase 1 (until Date 2024-05-14T18:00:00Z)

The sales are limited to 1 Batch per account.

The total number for sale is:
* **50 batches** +  Reservations
* (with a limit of 100)

#### Pre-sales Phase 2 (until date 2024-05-21T18:00:00Z)

Unlimited sales. Every account can purchase batches until everything is sold.

Reservations are canceled.


#### Launch

Sold $BRO are transferred to individual accounts.

Pre-sales incomes (KDA) are transferred to the public treasury module.

Liquidity (KDA + 40.0 $BRO) is transferred to the DEX.

$BRO can then only be bought on the free market.


## Minimum Holdings and registering
To be a member of the brother's community, you need to hold at least **0.2 $BRO**.
Otherwise you will be kicked out the channel by the bot.

Every user has to register via bot to the smart contract *bro-registry*.
To guarantee confidentiality, TG accounts are encrypted on-chain. And only the operator of the
bot knows the password that can associate a TG account to a $BRO account.

## Mining

$BRO is mined by tipping. Tips can be obtained in Brothers TG group by doing KCP
(KCP means Kadena Culture Production = Producing original Meme).
The tip amount is **1 GiDoug** (**0.001 $BRO**). To limit inflation, the smart-contract enforces a maximum of 10 tips / hour.

Tips are paid from the *Public Treasury*.

## Liquidity Management + Self pumping
The Liquidity reserved **40.0 $BRO** + KDA income from pre-sales (expected 1000.0 KDA) are owned by the Smart Contract (= the community).
There are 100% deployed on eckoDex for liquidity.

Earned DEX fees are automatically:
* **$BRO**: Transferred to the *Public Treasury* (to be used as future tips)
* **KDA**: Swapped to $BRO (self pumping) and transferred to the *Public Treasury*

(Expected $BRO initial price = 25.0 KDA)

## Contracts and Governance
- **token contract**: Governance by a multi-sig... And after some days/weeks governance will completely be disabled and contract locked.
- **pre-sales contract**: Governance by a multi-sig... Temporary contract. Will have no more usage after pre-sales.
- **public-treasury contract**: Governance by a multi-sig. There is no plan to lock the governance... Allowing to upgrade treasury management's policy.

## Contracts and Deployment addresses (chain 1,2 and 8):

- **Namesapce**: `n_582fed11af00dc626812cd7890bb88e72067f28c`

### Contracts (chain 2)
- **Token contract**: `n_582fed11af00dc626812cd7890bb88e72067f28c.bro`
- **Pre-sales contract**: `n_582fed11af00dc626812cd7890bb88e72067f28c.bro-pre-sales`
- **Treasury contract**: `n_582fed11af00dc626812cd7890bb88e72067f28c.bro-treasury`
- **Registry contract**: `n_582fed11af00dc626812cd7890bb88e72067f28c.bro-Registry`

### Accounts (chain 2)
- **Pre-sales account ($BRO)**: `c:Qi4upvWMxGhezfOLjGSTKnWxrtIZPf4HfBGmDtJSMZ4`
- **Pre-sales account (KDA)**: `c:ZmIEJnDzYCQMKtqSgPdF-YUr9YsNznQNOTPmuWoX6XM`
- **Treasury liquidity account (KDA,$BRO and Ecko liquidity tokens)**: `c:J9WSVPzUCrwmz9B3iexkGZPquLv4GODtFB_MQ98_MHs`
- **Main Treasury account ($BRO)**: `c:97hM74MQUX0nbNCiQVobw1P8LPWLQP1Zqq6F9-NHtqY`
- **Bot Gas (KDA)**: `r:n_582fed11af00dc626812cd7890bb88e72067f28c.bot`

### Keysets (chain 2)
- **Governance**: `n_582fed11af00dc626812cd7890bb88e72067f28c.governance`
- **Bot**: `n_582fed11af00dc626812cd7890bb88e72067f28c.bot`
- **Sales administration**: `n_582fed11af00dc626812cd7890bb88e72067f28c.sales-operator`
