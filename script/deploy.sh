#!/bin/bash

# Deploy RebasedOFT to Base Sepolia
forge create src/RebasedOFT.sol:RebasedOFT \
    --rpc-url https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY \
    --private-key $DEPLOYER_KEY \
    --verify \
    --verifier blockscout \
    --verifier-url https://base-sepolia.blockscout.com/api/ \
    --constructor-args "Rebased Staked Ether" "rebETH" "0x6EDCE65403992e310A62460808c4b910D972f10f" "0x1c46D242755040a0032505fD33C6e8b83293a332"
