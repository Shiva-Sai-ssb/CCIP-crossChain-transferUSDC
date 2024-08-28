# TransferUSDC Forked Test

This repository contains a test suite written in Solidity using the Foundry framework. The test focuses on the **TransferUSDC** contract, simulating cross-chain USDC transfers between Avalanche Fuji and Ethereum Sepolia networks.

## Overview

### Test Contracts

- **TransferUSDC:** Manages the transfer of USDC tokens across chains.
- **SwapTestnetUSDC:** Handles token swapping on the testnet.
- **CrossChainReceiver:** Receives and processes cross-chain messages.
- **CCIPLocalSimulatorFork:** Simulates cross-chain interactions locally.
- **MockCCIPRouter:** Mock implementation of the CCIP router for testing.

### Test Scenario

1. **Setup Phase:**

   - Deploy the `CCIPLocalSimulatorFork` and `MockCCIPRouter` contracts.
   - Deploy `TransferUSDC`, `SwapTestnetUSDC`, and `CrossChainReceiver` contracts.
   - Configure contracts for cross-chain communication and add necessary permissions.

2. **Testing Phase:**
   - **Transfer USDC:** Approve and initiate a USDC transfer from Avalanche Fuji to Ethereum Sepolia.
   - **Verify Gas Usage:** Record and log the gas used for the transfer, increase it by 10%, and perform the transfer again.
   - **Assertions:** Verify the balances and confirm the transfer was successful.

### Key Functions

- **setUp:** Initializes the test environment by deploying contracts and setting up cross-chain communication.
- **testTransferUSDCCrossChain:** Tests the transfer of USDC across chains and verifies the gas usage.

## How to Run the Tests

1. **Install Foundry:**
   Follow the [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation) to set up Foundry on your system.

2. **Clone the Repository:**

   ```bash
   git clone https://github.com/Shiva-Sai-ssb/ccip-crossChain-transferUSDC.git
   cd ccip-crossChain-transferUSDC
   ```

3. **Install Dependencies:**

   ```bash
   forge install
   ```

4. **Create and Configure `.env` File:**

   Create a `.env` file in the root of the `foundry` directory with the following content:

   ```plaintext
   AVALANCHE_FUJI_RPC_URL=<your_avalanche_fuji_rpc_url>
   ETHEREUM_SEPOLIA_RPC_URL=<your_ethereum_sepolia_rpc_url>
   ```

   Replace `<your_avalanche_fuji_rpc_url>` and `<your_ethereum_sepolia_rpc_url>` with the appropriate RPC URLs for Avalanche Fuji and Ethereum Sepolia networks.

5. **Run the Tests:**

   ```bash
   forge test -vv
   ```

   This will execute the test file and display the output, including logs generated by `console.log` statements.

## Test Logs

The test output includes the following key logs:

- Initial and final USDC balances of the user.
- Deployment addresses of the `CCIPLocalSimulatorFork`, `MockCCIPRouter`, `TransferUSDC`, `SwapTestnetUSDC`, and `CrossChainReceiver` contracts.
- Approval and initiation of the USDC transfer.
- Gas usage details and results of the transfer.

## Test Output

The following is the test output from running the Foundry test:

```bash
shiva-sai@ssb:CCIP-crossChain-transferUSDC$ forge test -vv
[⠒] Compiling...
No files changed, compilation skipped

Ran 1 test for test/test.t.sol:TransferUSDCForkedTest
[PASS] testTransferUSDCCrossChain() (gas: 800862)
Logs:
  User USDC Balance (Initial):  15000000
  Setup complete: transferUSDCInstance, swapInstance, receiverInstance deployed.
  Approval Amount: 2000000
  Amount to Send: 1000000
  Approved USDC for transferUSDCInstance.
  First Transfer
  Initiated USDC transfer.
  Gas used in transaction: 268479
  Total Gas used (plus 10 percent): 295326
  Second Transfer
  User USDC Balance (Final): 13000000

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 37.15s (15.20s CPU time)

Ran 1 test suite in 37.17s (37.15s CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

This detailed output shows the steps taken during the test execution, including contract deployments, setup of cross-chain communication, and the successful execution and verification of the USDC transfer.
