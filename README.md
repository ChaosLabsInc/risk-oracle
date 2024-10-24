# Edge Risk Oracle by Chaos Labs

The Chaos Labs Risk Oracle is a smart contract that serves as a dynamic oracle for risk parameters. It allows authorized senders to publish and update risk parameters, which can be queried by other contracts or off-chain systems.

## Features

- Authorized senders can publish risk parameter updates
- Support for different types of updates
- Bulk update functionality
- Historical tracking of parameter changes
- Query functionality for latest updates by type and market
- Owner-controlled management of authorized senders and update types

## Getting Started

### Prerequisites

- Git
- Foundry (for development and testing)
- An Ethereum wallet with some ETH for deployment

### Cloning the Repository

To get started with RiskOracle, clone the repository to your local machine:

```bash
git clone https://github.com/ChaosLabsInc/risk-oracle.git
cd risk-oracle
```

### Installing Dependencies

After cloning the repository, install the necessary dependencies:

```bash
forge install
```

## Contract Structure

The main contract is `RiskOracle.sol`, which implements the following key components:

- `RiskParameterUpdate`: A struct that holds details about each update
- `publishRiskParameterUpdate`: Function to publish a single update
- `publishBulkRiskParameterUpdates`: Function to publish multiple updates in one transaction
- `getUpdateById`: Function to retrieve an update by ID
- `getLatestUpdateByParameterAndMarket`: Function to fetch the latest update for a specific parameter and market
- Access control functions for managing authorized senders and update types

## Setup and Deployment

### Contract Deployment Setup

1. Set up your environment variables as described in the "Setting Up Environment Variables" section above.

2. Use the provided deployment script `DeployRiskOracle.s.sol`:

3. Modify the `description`, `initialSenders` and `initialUpdateTypes` in the script to match your desired initial configuration.

4. Compile the contracts:

   ```bash
   forge build
   ```

5. Deploy the contract using the script:

   ```bash
   forge script script/DeployRiskOracle.s.sol:DeployRiskOracle --rpc-url $RPC_URL --broadcast
   ```

6. After deployment, note the address of the deployed contract. You'll need this to interact with the contract.

## Testing

A comprehensive test suite is provided in `RiskOracleTest.t.sol`. It covers various scenarios including:

- Access control for adding/removing authorized senders
- Adding new update types
- Publishing updates
- Querying updates

To run the tests:

```bash
forge test
```

## Usage

1. Use the owner account to manage authorized senders and update types as needed.
2. Authorized senders can publish updates using `publishRiskParameterUpdate` or `publishBulkRiskParameterUpdates`.
3. Other contracts or off-chain systems can query the latest updates using the provided getter functions.

## Development

This project uses Foundry for development and testing. Make sure you have Foundry installed and properly set up before working on this project.
