# Rebased Protocol

Enabling cross-chain rebasing for staked tokens, beginning with stETH.

This repository implements several approaches to enable rebasing tokens across different chains.

## Architecture Overview

### Rebased (LayerZero Read)

Leverages LayerZero's `lzRead` functionality to retrieve balance updates from mainnet stETH. While the codebase is fully implemented, deployment encountered challenges with DVN and executor configurations for cross-chain `lzRead` operations.

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

Utilizes Scroll's native `L1SLOAD` precompile to access L1 state in real-time, providing immediate stETH balance synchronization without relying on external oracles.

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
├── YieldVerifier.sol     # EIP-4788 verifier
├── external/
│   └── IStETH.sol        # stETH interface
├── mocks/
│   ├── MockStakedEth.sol # Test mock
│   └── SlotStorage.sol   # Storage utils
└── scroll/
    ├── ScrollRebased.sol # L2 token
    └── ScrollBridge.sol  # L1 bridge
```

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
