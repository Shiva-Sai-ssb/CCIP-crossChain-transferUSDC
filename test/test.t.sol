// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console, Vm} from "forge-std/Test.sol";
import {TransferUSDC} from "src/TransferUSDC.sol";
import {SwapTestnetUSDC} from "src/SwapTestnetUSDC.sol";
import {CrossChainReceiver} from "src/CrossChainReceiver.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {MockCCIPRouter} from "@chainlink/contracts-ccip/src/v0.8/ccip/test/mocks/MockRouter.sol";

contract TransferUSDCForkedTest is Test {
    CCIPLocalSimulatorFork public localSimulatorFork;
    TransferUSDC public transferUSDCInstance;
    SwapTestnetUSDC public swapInstance;
    CrossChainReceiver public receiverInstance;
    MockCCIPRouter public mockRouter;

    address public user = 0xfA998CbA98Ec970dE4DDfD5eAA220c80F9BdBc0A;

    IERC20 public usdcOnAvalancheFuji;
    IERC20 public usdcOnEthereumSepolia;

    Register.NetworkDetails fujiNetworkDetails;
    Register.NetworkDetails sepoliaNetworkDetails;

    uint256 fujiFork;
    uint256 sepoliaFork;

    address constant usdcFujiAddress = 0x5425890298aed601595a70AB815c96711a31Bc65;
    address constant usdcSepoliaAddress = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant compoundUsdcTokenSepolia = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant fauceteerSepolia = 0x68793eA49297eB75DFB4610B68e076D2A5c7646C;
    address constant cometSepolia = 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e;

    function setUp() public {
        string memory FUJI_RPC_URL = vm.envString("AVALANCHE_FUJI_RPC_URL");
        string memory SEPOLIA_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");

        fujiFork = vm.createSelectFork(FUJI_RPC_URL);
        sepoliaFork = vm.createFork(SEPOLIA_RPC_URL);

        localSimulatorFork = new CCIPLocalSimulatorFork();
        mockRouter = new MockCCIPRouter();
        vm.makePersistent(address(localSimulatorFork), address(mockRouter));

        fujiNetworkDetails = localSimulatorFork.getNetworkDetails(block.chainid);

        usdcOnAvalancheFuji = IERC20(usdcFujiAddress);

        vm.startPrank(user);
        transferUSDCInstance = new TransferUSDC(address(mockRouter), fujiNetworkDetails.linkAddress, usdcFujiAddress);
        vm.stopPrank();

        console.log("User USDC Balance (Initial): ", usdcOnAvalancheFuji.balanceOf(address(user)));

        localSimulatorFork.requestLinkFromFaucet(address(transferUSDCInstance), 5 ether);

        vm.selectFork(sepoliaFork);

        sepoliaNetworkDetails = localSimulatorFork.getNetworkDetails(block.chainid);

        usdcOnEthereumSepolia = IERC20(usdcSepoliaAddress);

        swapInstance = new SwapTestnetUSDC(usdcSepoliaAddress, compoundUsdcTokenSepolia, fauceteerSepolia);

        receiverInstance = new CrossChainReceiver(address(mockRouter), cometSepolia, address(swapInstance));

        receiverInstance.allowlistSourceChain(sepoliaNetworkDetails.chainSelector, true);
        receiverInstance.allowlistSender(address(transferUSDCInstance), true);

        vm.makePersistent(address(receiverInstance));

        console.log("Setup complete: transferUSDCInstance, swapInstance, receiverInstance deployed.");
    }

    function testTransferUSDCCrossChain() public {
        vm.selectFork(fujiFork);

        uint256 approvalAmount = 2_000_000;
        uint256 amountToSend = 1_000_000;
        uint64 gasLimit = 500_000;

        console.log("Approval Amount: %d", approvalAmount);
        console.log("Amount to Send: %d", amountToSend);

        vm.startPrank(user);
        transferUSDCInstance.allowlistDestinationChain(sepoliaNetworkDetails.chainSelector, true);
        usdcOnAvalancheFuji.approve(address(transferUSDCInstance), approvalAmount);
        console.log("Approved USDC for transferUSDCInstance.");

        vm.recordLogs();
        transferUSDCInstance.transferUsdc(
            sepoliaNetworkDetails.chainSelector, address(receiverInstance), amountToSend, gasLimit
        );
        console.log("First Transfer");
        console.log("Initiated USDC transfer.");

        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 totalGasConsumed;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("MsgExecuted(bool,bytes,uint256)")) {
                (,, uint256 gasUsed) = abi.decode(logs[i].data, (bool, bytes, uint256));
                console.log("Gas used in transaction: %d", gasUsed);
                totalGasConsumed += gasUsed;
            }
        }

        uint64 totalGasPlusTenPercent = uint64((totalGasConsumed * 110) / 100); // Increase by 10%
        console.log("Total Gas used (plus 10 percent): %d", totalGasPlusTenPercent);

        // Perform the second transfer with the increased gas limit
        console.log("Second Transfer");
        transferUSDCInstance.transferUsdc(
            sepoliaNetworkDetails.chainSelector, address(receiverInstance), amountToSend, totalGasPlusTenPercent
        );

        vm.stopPrank();
        console.log("User USDC Balance (Final): %d", usdcOnAvalancheFuji.balanceOf(user));

        localSimulatorFork.switchChainAndRouteMessage(sepoliaFork);
    }
}
