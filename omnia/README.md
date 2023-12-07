# Omnia
An oracle client written in bash. It has 2 services feed and relay.

This repository only has the code for omnia relay service.

Relay service will listen to new messages in the transport layer and include the pricing data and signatures in a single ethereum transaction and publish on chain

To deploy feed, please go to https://github.com/soodup/omnia-feed

## Quickstart


```
docker-compose up
docker-compose -f docker-compose.yml exec -d omnia_relay sh -c "spire agent -c '/home/omnia/spire.hcl'"
```

## Config and Deployment

### Config

1) Set the “interval” cron duration (seconds) in `omnia/config/relay-ethereum-sepolia.json` (for testnet) that omnia relay service will check for new price updates in the p2p network and publish on chain.

For example,
```json
"options": {
    "interval": 60
   }
```
2) Set the supported feed pairs in `omnia/config/relay-ethereum-sepolia.json` and `omnia/docker/spire/config/relay_config.hcl` for whitelisting in spire (p2p network)

For example,
```json
  "pairs": {
    "cryptopunks/appraisal":{"msgExpiration":300,"msgSpread":0.5}
  }
```
```hcl
spire {
  # List of pairs that are collected by the spire node. Other pairs are ignored.
  pairs = [
    "cryptopunksappraisal"
  ]
}
```
3) Set the `ETH_RPC_URL` and `CFG_ETH_CHAIN_ID` in docker-compose.yml

For example,
```yml
    environment:
       ETH_RPC_URL: "https://rpc-sepolia.rockx.com/"
       CFG_ETH_CHAIN_ID: 11155111
```

4) Set the wallet address and password that will be used to sign the messages in `omnia/config/relay-ethereum-sepolia.json`
   Test wallet keystore and password are present in `omnia/docker/keystore/2.json` and `omnia/docker/keystore/pass`.

For example,
```json
  "mode": "feed",
  "ethereum": {
    "from": "0xe3ced0f62f7eb2856d37bed128d2b195712d2644",
    "keystore": "/home/omnia/.ethereum/keystore",
    "password": "/home/omnia/.ethereum/keystore/pass"
  }
```


5) Also set the same in env variables `CFG_ETH_FROM`, `CFG_ETH_KEYS`, `CFG_ETH_PASS` in `omnia/docker-compose.yml`.

For example,
```yaml
services:
  omnia_feed:
    image: upshot-omnia-relay
    environment:
      CFG_ETH_FROM: "0xe3ced0f62f7eb2856d37bed128d2b195712d2644"
      CFG_ETH_KEYS: "/home/omnia/.ethereum/keystore"
      CFG_ETH_PASS: "/home/omnia/.ethereum/keystore/pass"
```
Also, set `ETH_VALUE` env var to set the eth value in the transaction.
```yaml
environment:
   ETH_VALUE: 1
```
Note: Make sure you have enough funds in the wallet to submit a txn.
### Deployment
- Run Docker compose file `omnia/docker-compose.yml` to start omnia relay service.
- Run `docker-compose -f docker-compose.yml exec -d omnia_relay sh -c "spire agent -c '/home/omnia/spire.hcl'"` to start spire agent process.
---
