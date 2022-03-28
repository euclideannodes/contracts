# euclidean-nodes testing with foundry

## Introduction
this is a test of the euclidean-nodes-contract using foundry-forge testing toolkit.
we are forking kovan locally to run our tests.

## setup

### prequisites
* `foundry`
* go to: https://onbjerg.github.io/foundry-book/getting-started/installation.html

### Configuration
* run `forge install` in your terminal to install dependencies
* run `forge remappings > remappings.txt` to make importing easier
* run this in your terminal: `ETH_RPC_URL="paste your kovan rpc url here"`

## Testing

### Locally forked kovan
* run `forge test --fork-url $ETH_RPC_URL -vv` in your terminal

 