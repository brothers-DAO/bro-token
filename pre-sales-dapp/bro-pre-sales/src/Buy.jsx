import { useState, useEffect, useRef } from 'react';
import { useDeepCompareMemo, useDeepCompareEffect } from "use-deep-compare";
import { Sidebar } from 'primereact/sidebar';
import { Button } from 'primereact/button';
import { RadioButton } from 'primereact/radiobutton';
import { Fieldset } from 'primereact/fieldset';
import { Divider } from 'primereact/divider';
import { FloatLabel } from 'primereact/floatlabel';
import { Panel } from 'primereact/panel';
import { InputText } from 'primereact/inputtext';
import { Messages } from 'primereact/messages';
import {useLocalPact, useLocalPactImmutable, usePreflight, submit, status} from './pact';
import {Decimal} from 'decimals'
import {Pact} from '@kadena/client'
import YAML from 'yaml'

const _to_key = g => g?.keys?.[0] ?? ""
const _to_decimal = v => v?(v.decimal?Decimal(v.decimal):Decimal(v)):Decimal(0)
const dec = (x) => ({"decimal":x.toString()})

const NETWORK = import.meta.env.VITE_NETWORK
const CHAIN = import.meta.env.VITE_CHAIN
const NS = import.meta.env.VITE_NS
const MOD = NS + ".bro-pre-sales"

import {createEckoWalletQuicksign, signWithChainweaver} from '@kadena/client'

const ecko = createEckoWalletQuicksign()

const SIGNERS = {ECKO:ecko, CWD:signWithChainweaver, CW:null}

const ecko_account = () => window.kadena.request({ method: 'kda_checkStatus', networkId:NETWORK})
                                                 .then((x) => {console.log(x); return x.account.account})

function useCoinDetails(acct)
{
  const {data} = useLocalPact(acct?`(coin.details "${acct}")`:null, NETWORK, CHAIN)
  return {details:data}
}

function useCoinGuard(acct)
{
  const {details} = useCoinDetails(acct)
  return {guard:details?.guard}
}

function useCoinBalance(acct)
{
  const {details} = useCoinDetails(acct)
  return {balance:details?.balance}
}



const make_trx = (acct, guard, sales_acct) => Pact.builder.execution(`(${MOD}.buy "${acct}" (read-keyset 'k))`)
                                                          .setMeta({sender:acct, chainId:CHAIN, gasLimit:2000})
                                                          .setNetworkId(NETWORK)
                                                          .addData("k", guard)
                                                          .addSigner(_to_key(guard), (withCapability) => [withCapability('coin.GAS'), withCapability('coin.TRANSFER', acct, sales_acct, dec(10.0))])
                                                          .createTransaction()


const MIN_BALANCE = Decimal("10.00002")

const ACCOUNT_OK_MESSAGE = {sticky: true, severity: 'success', summary: 'Account OK', detail: 'KDA Account OK', closable: false}
const KEY_ERR_MESSAGE = {sticky: true, severity: 'error', summary: 'Error', detail: 'Invalid account or guard', closable: false}
const BALANCE_ERR_MESSAGE = {sticky: true, severity: 'error', summary: 'Error', detail: `Insufficient Balance. ${MIN_BALANCE.toString()} KDA is required on chain 2`, closable: false}
const WAITING_SIG_MESSAGE = {sticky: true, severity: 'info', summary: 'Wallet signature', detail: "Waitin for wallet signature", closable: false}
const SIGNATURE_OK = {sticky: true, severity: 'success', summary: 'Signature OK', detail: "Wallet successfully signed the transaction", closable: true}
const SIGNATURE_ERROR = {sticky: true, severity: 'error', summary: 'Error in signature', detail: "Wallet refused to sign the transaction", closable: true}
const SEND_OK = {sticky: true, severity: 'success', summary: 'Sent', detail: "Transaction submitted to the network", closable: true}
const SEND_ERROR = {sticky: true, severity: 'error', summary: 'Send error', detail: "An error occured when sending the trnasaction", closable: true}
const WAITING_FOR_TRANSACTION = {sticky: true, severity: 'info', summary: 'Not confirmed', detail: "Waiting for network confirmation", closable: true}
const POLL_ERROR= {sticky: true, severity: 'error', summary: 'Poll error', detail: "Unable to retrieve the confirmation of the transaction", closable: true}
const CLIPBOARD_MESSAGE = {sticky: true, severity: 'warn', summary: 'Transaction copied', detail: "Transaction copied in the clipboard. Please paste and submit it in the Chainweaver's SigBuilder", closable: true}


function result_to_msg(r)
{
    return {sticky: true, severity: r.status=="success"?'success':'error',
                          summary: r.status=="success"?'Transaction confirmed':'Transaction error',
                          detail: JSON.stringify(r) , closable: true}
}

function BuySideBarContent()
{
  const {data:sales_acct} = useLocalPactImmutable(`${MOD}.SALES-ACCOUNT`, NETWORK, CHAIN);
  const {data:_amount_per_batch} = useLocalPactImmutable(`${MOD}.AMOUNT-PER-BATCH`, NETWORK, CHAIN)
  const {data:_price_per_batch} = useLocalPactImmutable(`${MOD}.PRICE-PER-BATCH`, NETWORK, CHAIN)
  const amount_per_batch = _to_decimal(_amount_per_batch)
  const price_per_batch = _to_decimal(_price_per_batch)

  const [wallet, setWallet] = useState("CW")
  const [account, setAccount] = useState("")
  const [sent, setSent] = useState(false)
  const [signProcessing, setSignProcessing] = useState(false)
  const msgs_a = useRef(null);
  const msgs_pf = useRef(null);
  const msgs_trx = useRef(null);
  const {guard} = useCoinGuard(account);
  const {balance} = useCoinBalance(account);

  const trx = useDeepCompareMemo(() => (account && _to_key(guard) && sales_acct)?make_trx(account, guard, sales_acct):null, [account, guard, sales_acct])

  const {data:pf_result, error:pf_error} = usePreflight(trx)

  const balance_ok = _to_decimal(balance).gte(MIN_BALANCE)

  useEffect(() => {if(wallet=="ECKO")
                    ecko.connect(NETWORK).then(x => console.log(x)).then(ecko_account).then(setAccount)
                  }, [wallet])

  function __updateMessages()
  {
    if(!account)
      msgs_a.current?.clear();
    else if(!_to_key(guard))
      msgs_a.current?.replace(KEY_ERR_MESSAGE);
    else if(!balance_ok)
      msgs_a.current?.replace(BALANCE_ERR_MESSAGE);
    else
      msgs_a.current?.replace(ACCOUNT_OK_MESSAGE)
  }

  useDeepCompareEffect(__updateMessages, [account, msgs_a, guard, balance])

  useDeepCompareEffect(()=> { if(pf_result)
                                msgs_pf.current?.replace({sticky: true, severity: 'success', summary: 'Preflight', detail: pf_result, closable: false});
                              else if(pf_error)
                                msgs_pf.current?.replace({sticky: true, severity: 'error', summary: 'Preflight', detail: pf_error.toString(), closable: false});
                              else
                                msgs_pf.current?.clear();
                            }, [pf_result,pf_error])

  const doCopyYAML = () => { msgs_trx.current?.clear();
                             const sigdata = {cmd:trx.cmd, sigs: JSON.parse(trx.cmd).signers.map((x)=>({pubKey:x.pubKey, sig:null}))}
                             return navigator.clipboard.writeText( YAML.stringify(sigdata))
                                                       .then(() => {msgs_trx.current?.show(CLIPBOARD_MESSAGE); return trx})}


  const doSign = () => {msgs_trx.current?.replace(WAITING_SIG_MESSAGE);
                        setSignProcessing(true);
                        return SIGNERS[wallet](trx).then( x => {console.log(x), msgs_trx.current?.show(SIGNATURE_OK); return x})
                                                   .catch(()=> msgs_trx.current?.show(SIGNATURE_ERROR))
                                                   .finally(() => {msgs_trx.current?.remove(WAITING_SIG_MESSAGE); setSignProcessing(false)})
                       }

  const doSubmit = cmd => {if(!cmd)
                            return;
                           setSignProcessing(true);
                           return submit(cmd).then(() => {msgs_trx.current?.show(SEND_OK); return cmd})
                                             .catch(() => msgs_trx.current?.show(SEND_ERROR))
                          }

  const doStatus = cmd => { if(!cmd)
                              return;
                            setSignProcessing(true);
                            setSent(true);
                            msgs_trx.current?.show(WAITING_FOR_TRANSACTION);
                            return status(cmd, NETWORK, CHAIN).then(x => {console.log(x); msgs_trx.current?.show(result_to_msg(x.result))})
                                                              .catch(() => msgs_trx.current?.show(POLL_ERROR))
                                                              .finally(()=> {setSignProcessing(false); msgs_trx.current?.remove(WAITING_FOR_TRANSACTION);})
                          }

  const onSignClick = () => SIGNERS[wallet]?doSign().then(doSubmit).then(doStatus)
                                           :doCopyYAML().then(doStatus)



  const WalletRadio = ({name, display, disabled}) => <div className="flex align-items-center m-1">
                                            <RadioButton disabled={disabled} value={name} onChange={(e) => setWallet(e.value)} checked={wallet==name} />
                                            <label className={disabled?"font-light ml-2 line-through":"ml-2"}>{display}</label>
                                          </div>

  const BroBotLink = () =>  <a href={import.meta.env.VITE_BRO_BOT} target="_blank"> Bro BOT </a>

  return <>
          <h1 className="my-0 text-center">Buy your $BRO: {amount_per_batch.toFixed(1)} $BRO for {price_per_batch.toFixed(1)} KDA</h1>
          <Divider />
          <Panel header="Important Notes" className="p-0 m-3">
            <ul className="py-0 m-0">
              <li className="mb-2"> If your wallet supports WalletConnect (Linx, Koala, Ecko Mobile), you can directly and easily buy using the <BroBotLink />  </li>
              <li className="mb-2"> After buying during pre-sales, as stated by the Smart-Contract, you will receive your $BRO tokens after launch. In the meantime, you can check on this frontend that your order has been recorded in the &quot;Sold batches&quot; panel. </li>
              <li className="mb-2"> This is a 100% community coin. 100% of the pre-sales incomes will be invested in liquidity in EckoDEX. Issuers don't make profits. This is enforced by a multi-sig Smart Contract.</li>
              <li> You can immediately add the token address into your wallet: <span style={{fontFamily: "monospace"}}>{NS}.bro</span> </li>
            </ul>
          </Panel>
          <Fieldset legend="Wallet" className="py-0">
            <WalletRadio name="CW" display="ChainWeaver SigBuilder (Web or Desktop)" />
            <WalletRadio name="CWD" display="ChainWeaver QuickSign API (Desktop only)" />
            <WalletRadio disabled={!ecko.isInstalled()} name="ECKO" display="EckoWallet" />
          </Fieldset>


          <div className="pt-5">
          <FloatLabel>
            <InputText id="account" disabled={wallet=="ECKO" || signProcessing} value={account} onChange={(e) => setAccount(e.target.value)} className="w-full"/>
              <label>Account</label>
          </FloatLabel>
          </div>
          <Messages ref={msgs_a} />
          <Messages ref={msgs_pf} />
          <Button className="mt-2" disabled={pf_result==null || signProcessing || sent} onClick={onSignClick} loading={signProcessing} label="Sign and Submit" />

          <Messages ref={msgs_trx} />
        </>

}


function BuySideBar({visible, onHide})
{
  return <Sidebar visible={visible} position="left" onHide={onHide} dismissable={false} className="w-6" >
          <BuySideBarContent />

        </Sidebar>
}

export {BuySideBar};
