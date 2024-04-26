import { useState } from 'react';
import { Button } from 'primereact/button';
import { Timeline } from 'primereact/timeline';
import { Card } from 'primereact/card';
import { Toolbar } from 'primereact/toolbar';
import { Panel } from 'primereact/panel';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Image } from 'primereact/image';

import {Decimal} from 'decimals'
import 'primereact/resources/themes/lara-light-indigo/theme.css'; //theme
import 'primereact/resources/primereact.min.css'; //core css
import 'primeicons/primeicons.css'; //icons
import 'primeflex/primeflex.css'; // flex
import './App.css';

import {useLocalPact, useLocalPactImmutable} from './pact';

import {BuySideBar} from './Buy.jsx';
import LOGO from './assets/BRO_64_64.png';


const _to_decimal = v => v?(v.dec?Decimal(v.dec):Decimal(v)):Decimal(0)

const NETWORK = import.meta.env.VITE_NETWORK
const CHAIN = import.meta.env.VITE_CHAIN
const NS = import.meta.env.VITE_NS
const MOD = NS + ".bro-pre-sales"

function usePhases()
{
  const {data} = useLocalPact(`[(${MOD}.in-phase-0), (${MOD}.in-phase-1), (${MOD}.in-phase-2), (${MOD}.ended)]`, NETWORK, CHAIN)

  return {phases:data??[false, false, false, false]}
}

function SalesTimeLine() {
  const {data:times} = useLocalPactImmutable(`[${MOD}.PHASE-0-START, ${MOD}.PHASE-1-START, ${MOD}.PHASE-2-START, ${MOD}.END-OF-PRESALES]`, NETWORK, CHAIN)
  const {phases} = usePhases()

  const events = [
        { status: 'Phase 0', date: times?.[0]?.time??"/", enabled:phases[0] || phases[1] || phases[2] || phases[3], text:"Only Pre‑reserved accounts (brothers) can buy a batch "},
        { status: 'Phase 1', date: times?.[1]?.time??"/", enabled:phases[1] || phases[2] || phases[3], text:"Sales limited to 50 batches (1 per account) + Pre‑reserved accounts" },
        { status: 'Phase 2', date: times?.[2]?.time??"/", enabled:phases[2] || phases[3], text:"Free sales limited to 100 batches"},
        { status: 'Launch', date:  times?.[3]?.time??"/", enabled:phases[3], text:"Tokens distribution / Secondary market on EckoDEX"}
    ];

    const customizedMarker = (item) => {
        if(!item.enabled)
          return null;
        return (
            <span className="flex w-2rem h-2rem align-items-center justify-content-center text-white border-circle z-1 shadow-1" style={{ backgroundColor: "green"}}>
                <i className="pi pi-check"></i>
            </span>
        );
    };

    const customizedContent = (item) => {
        return (
            <Card title={item.status} subTitle={item.date} className="bg-black-alpha-10 p-0" >
            {item.text && <div className="text-xs">{item.text} </div>}
            </Card>
        );
    };

    return (
        <Panel header="Pre-sales schedule"  style={{ minWidth: '40rem', maxWidth:'40rem' }}>
            <Timeline value={events} align="alternate" className="customized-timeline" marker={customizedMarker} content={customizedContent} />
        </Panel>
    )
}




function DashBoardPanel()
{
  const {data:counters} = useLocalPact(`(+ {'available:(${MOD}.available-for-free-sales)} (${MOD}.get-counters))`, NETWORK, CHAIN)
  const {phases} = usePhases()
  const phase_str = phases[3]?"Launched"
                   :(phases[2]?"Phase 2"
                   :(phases[1]?"Phase 1"
                   :(phases[0]?"Phase 0"
                   :"/")))

  const __int = x => x?(x.int.toString()+" / 100"):"/";


  return <Panel header="Dash Board"  >
            <div className="flex flex-row gap-2">
            <Card className="flex-1">
              <div className="flex flex-column gap-1">
              <span className="text-secondary text-sm">Current Phase</span>
              <span className="font-bold text-lg">{phase_str}</span>
              </div>
            </Card>

            <Card className="flex-1">
              <div className="flex flex-column gap-1">
              <span className="text-secondary text-sm">Resevervations</span>
              <span className="font-bold text-lg">{__int(counters?.reserved)}</span>
              </div>
            </Card>

              <Card className="flex-1">
                <div className="flex flex-column gap-1">
                <span className="text-secondary text-sm">Sold batches</span>
                <span className="font-bold text-lg">{__int(counters?.sold)}</span>
                </div>
              </Card>

              <Card className="flex-1">
                <div className="flex flex-column gap-1">
                <span className="text-secondary text-sm">Available for sale</span>
                <span className="font-bold text-lg">{__int(counters?.available)}</span>
                </div>
              </Card>

          </div>


          </Panel>

}

function Reservations()
{
  const {data} = useLocalPact(`(${MOD}.get-reservations)`, NETWORK, CHAIN)
  const reserv = data?data.map(({account,reserved}) => ({account:account, reserved:reserved.int.toString()})):null;

  return <Panel header="Reservations" toggleable collapsed>
          <DataTable value={reserv} tableStyle={{ minWidth: '30rem' }} paginator rows={5}>
            <Column field="account" headerClassName="text-xs"  header="Account" sortable className="text-xs" style={{ width: '75%', fontFamily:"monospace" }}></Column>
            <Column field="reserved" headerClassName="text-xs"  header="Qty" style={{ width: '25%', fontFamily:"monospace" }}></Column>
          </DataTable>
          </Panel>
}

function Sales()
{
  const {data} = useLocalPact(`(${MOD}. get-sales)`, NETWORK, CHAIN)
  const {data:_amount_per_batch} = useLocalPactImmutable(`${MOD}.AMOUNT-PER-BATCH`, NETWORK, CHAIN)
  const amount_per_batch = _to_decimal(_amount_per_batch)

  const reserv = data?data.map(({account,bought}) => ({account:account, amount:amount_per_batch.mul(bought.int).toString(), bought:bought.int.toString()})):null;

  return <Panel header="Sold batches" toggleable>
          <DataTable value={reserv} tableStyle={{ minWidth: '30rem' }}  paginator rows={10}>
            <Column field="account" headerClassName="text-xs" header="Account" sortable className="text-xs" style={{ width: '75%', fontFamily:"monospace" }}></Column>
            <Column field="bought" headerClassName="text-xs"  header="Qty" sortable style={{ width: '12%', fontFamily:"monospace" }}></Column>
            <Column field="amount" headerClassName="text-xs"  header="$BRO Amount" style={{ width: '13%', fontFamily:"monospace" }}></Column>
          </DataTable>
          </Panel>
}


const GHButton = () => <a style={{ fontSize: '1.6rem' }} href="https://github.com/CryptoPascal31/bro-token" target="_blank" rel=" noopener noreferrer" className="mx-1 no-underline p-button-rounded p-button-raised p-button-outlined p-button-text pi pi-github p-button p-button-icon-only" />
const InfoButton = () => <a style={{ fontSize: '1.6rem' }} href="https://github.com/CryptoPascal31/bro-token/blob/main/README.md" target="_blank" rel="noopener noreferrer" className="mx-1  no-underline p-button-rounded p-button-raised p-button-outlined p-button-text pi pi-info-circle p-button p-button-icon-only" />


function BuyButton()
{
  const [open, setOpen] = useState(false)

  return <> <BuySideBar visible={open} onHide={()=> setOpen(false)} />
            <Button size="large" raised onClick={() => setOpen(true)} icon="pi pi-shopping-cart" label="Buy with EckoWallet or Chainweaver" />
         </>
}

function App() {
  return (
    <div className="flex flex-column row-gap-4">
      <Toolbar className="shadow-4 border-round-3xl"
               start={<> <GHButton /> <InfoButton /> </>}
               center={<div className="flex text-5xl font-bold"> <Image src={LOGO} height="48" className="mt-0"/>&nbsp; $BRO Pre-Sales &nbsp; <Image src={LOGO} height="48" className="mt-0"/></div>}
               end={<div className="font-italic text-xs text-right"> {NETWORK} / chain {CHAIN} <br /> {NS}</div>} />
      <div className="flex flex-row gap-2 ">

      <SalesTimeLine />
        <div className="flex flex-column gap-2">
          <BuyButton />
          <DashBoardPanel />
          <Reservations />
          <Sales />

        </div>
      </div>

    </div>
  );
}

export default App;
