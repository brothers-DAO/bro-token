import {createClient, Pact} from '@kadena/client'
import useSWR from 'swr';
import useSWRImmutable from 'swr/immutable'

const LOCAL_GAS_LIMIT = 150000



const client = createClient()

function local_check(cmd, options)
{
  return client.local(cmd, options)
        .then((resp) => { if(resp?.result?.status !== 'success')
                           {console.warn(resp); throw Error(`Error in local call:${resp?.result?.error?.message}`);}
                          else
                            return resp.result.data;});
}

function local_pact(pact_code, network, chain)
{
  const cmd = Pact.builder
                  .execution(pact_code)
                  .setMeta({chainId:chain, gasLimit:LOCAL_GAS_LIMIT})
                  .setNetworkId(network)
                  .createTransaction();
  return local_check(cmd, {signatureVerification:false, preflight:false});
}

function submit(cmd)
{
  return client.submitOne(cmd)
}

function status(cmd, network, chain)
{
  return client.pollStatus({requestKey:cmd.hash, chainId:chain , networkId: network},
                           {timeout:1000*300, interval:5000})
               .then( x=> x?.[cmd.hash])
}

function usePreflight(cmd)
{
  return useSWRImmutable(cmd?["/prefilght", cmd.hash]:null,  () => local_check(cmd, {signatureVerification:false, preflight:true}));
}

function useLocalPact(code, network, chain)
{
  return useSWR((code && network && chain)?["/pact",code, network, chain]:null, x  => local_pact(x[1],x[2],x[3]));
}

function useLocalPactImmutable(code, network, chain)
{
  return useSWRImmutable((code && network && chain)?["/pact",code, network, chain]:null, x  => local_pact(x[1],x[2],x[3]));
}

export {local_check, local_pact, useLocalPact, useLocalPactImmutable, usePreflight, submit, status}
