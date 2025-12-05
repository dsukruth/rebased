# Rebased Protocol

Rebased Protocol enables rebasing tokens, such as stETH, to function seamlessly across chains while retaining rebase events. The system leverages multiple innovative technologies to ensure accurate, real-time rebase synchronization across different blockchain networks.

## Overview

This project allows rebasing tokens to maintain their rebasing mechanics when bridged across chains. Scroll's L1SLOAD precompile provides quick and cost-effective access to L1 blockchain and contract states, enabling immediate and accurate rebase updates. EIP-4788 ensures Lido Oracle reports are consistent with specific block roots, protecting data integrity through block root verification, epoch validation, and ordered report processing. LayerZero's lzRead enables reliable cross-chain communication, ensuring compatibility and accurate data flow.

## Architecture Overview

### Rebased (LayerZero Read)

Leverages LayerZero's `lzRead` functionality for reliable cross-chain communication, ensuring compatibility and accurate data flow. The system retrieves balance updates from mainnet stETH using lzRead's dependable cross-chain messaging. While the codebase is fully implemented, deployment encountered challenges with DVN and executor configurations for cross-chain `lzRead` operations.

**Deployment:**
- `Rebased`: `0x8eE74Bfc34e7e2e257887d54a59DAD1b2BD80Cc3` (Base Sepolia - currently inactive)

### RebasedOFT & StakedEthAdapter

An OFT-based approach for cross-chain rebasing:
- `StakedEthAdapter`: Receives stETH deposits on mainnet and facilitates bridging through OFT
- `RebasedOFT`: Cross-chain OFT implementation supporting rebasing token mechanics
- Rebase synchronization handled by `setRebaseData()` - designed to be invoked by decentralized infrastructure such as EigenLayer AVS

**Deployments:**
- `StakedEthAdapter`: `0x19180d8aF15dd42a868840d9A31A09Ed98711422` (Ethereum Sepolia)
- `RebasedOFT`: `0x5F1A2810eDa7B75A8934Ae15b1c0ADcDAE315bc3` (Base Sepolia)

### Scroll Implementation

Utilizes Scroll's native `L1SLOAD` precompile to access L1 state in real-time, providing immediate stETH balance synchronization without relying on external oracles. The L1SLOAD precompile enables quick and cost-effective access to L1 blockchain and contract states, allowing for instant rebase updates directly from the source chain.

**Deployments:**
- `ScrollBridge`: `0x2b819A18d532456F273d59Ed4788d97b52fa6375` (Ethereum Sepolia)
- `ScrollRebased`: `0xfbB5eb88a4C99ae2C5b84184C84460f172f0eC06` (Scroll Devnet)

## Project Structure

```
src/
├── Rebased.sol           # LZ Read implementation
├── IRebased.sol          # Interface
├── RebasedOFT.sol        # OFT token
├── StakedEthAdapter.sol  # Mainnet adapter
├── YieldVerifier.sol     # EIP-4788 verifier for Lido Oracle report validation
├── external/
│   └── IStETH.sol        # stETH interface
├── mocks/
│   ├── MockStakedEth.sol # Test mock
│   └── SlotStorage.sol   # Storage utils
└── scroll/
    ├── ScrollRebased.sol # L2 token
    └── ScrollBridge.sol  # L1 bridge
```

## Key Features

- **Cross-Chain Rebasing**: Maintains rebase events when tokens are bridged across chains
- **Real-Time Updates**: Uses Scroll's L1SLOAD for instant L1 state access without oracle delays
- **Data Integrity**: EIP-4788 verification ensures Lido Oracle reports match block roots
- **Reliable Communication**: LayerZero's lzRead provides dependable cross-chain data flow
- **Multiple Approaches**: Implements various strategies for different chain architectures

## Getting Started

```bash
# Install dependencies
forge install

# Compile contracts
forge build

# Run test suite
forge test

# Deploy contracts
./script/deploy.sh
```

## License

MIT
