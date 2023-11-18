// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    constructor() {}

    event EnterRaffle(address indexed participant);
    event PickWinner(address indexed winner);

    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 interval;
    uint256 entranceFee;
    address vrfCoordinator;

    address public player = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        vm.deal(player, STARTING_BALANCE);
        (,, interval, entranceFee,, vrfCoordinator,,) = helperConfig.activeNetworkConfig();
    }

    /**
     * @dev test enterRaffle
     */
    function testEnterRaffle_ShouldInOpenState_WhenInitializes() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleStatus.OPEN);
    }

    function testEnterRaffle_ShouldReverts_WhenPaymentIsNotEnough() public {
        vm.prank(player);
        vm.expectRevert(Raffle.Raffle__NotEnoughFee.selector);
        raffle.enterRaffle();
    }

    function testEnterRaffle_ShouldRecordsPlayers_WhenTheyEnter() public {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == player);
    }

    function testEnterRaffle_ShouldEmitsEvent_WhenEnterSuccessfully() public {
        vm.prank(player);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnterRaffle(player);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testEnterRaffle_ShouldRefusesEnter_WhenCalculating() public RaffleEnterAndTimePassed {
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
    }

    /**
     * @dev test checkUpkeep
     */
    function testCheckUpkeep_ShouldReturnsFalse_WhenBalanceNotEnough() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 3);
        (bool upKeepNeeded,) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpkeep_ShouldReturnsFalse_WhenTimeNotPass() public {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        (bool upKeepNeeded,) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpkeep_ShouldReturnFalse_WhenNotOpen() public RaffleEnterAndTimePassed {
        raffle.performUpkeep("");
        (bool upKeepNeeded,) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpkeep_ShouldReturnsTrue_WhenParametersAreRight() public RaffleEnterAndTimePassed {
        (bool upKeepNeeded,) = raffle.checkUpkeep("");
        assert(upKeepNeeded);
    }

    /**
     * @dev test performUpkeep
     */

    function testPerformUpkeep_ShouldRunsCorrectlly_WhenUpkeepNeededIsTrue() public RaffleEnterAndTimePassed {
        raffle.performUpkeep("");
    }

    function testPerformUpkeep_ShouldReverts_WhenUpkeepNotNeeded() public {
        // 0x90193C961A926261B756D1E5bb255e67ff9498A1
        console.log(address(raffle));
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, raffleState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeep_ShouldUpdatesStateAndEmitsRequest_WhenUpkeepNeededIsTrue()
        public
        RaffleEnterAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestId = logs[0].topics[2];
        Raffle.RaffleStatus raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleStatus.CALCULATING);
    }

    modifier RaffleEnterAndTimePassed() {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 3);
        _;
    }

    modifier SkipFocker() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    /**
     * @dev test fulfillRandomWords
     * @notice Fuzzing test at testRaffle_ShouldOnlyBeCalled_WhenPerformUpkeepCorrectlly
     */
    function testFulfillRandomWords_ShouldOnlyBeCalled_WhenPerformUpkeepCorrectlly(uint256 randomRequestId)
        public
        SkipFocker
        RaffleEnterAndTimePassed
    {
        /**
         * because only when we call the performUpkeep function, and it will call the requestRandomWords function to get a requestId which the fulfillRandomWords function needs.So if we do not call the performUpkeep function, we will get a revert error.you can check it in the VRFCoordinatorV2Mock contract.
         */
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWords_ShouldPicksAWinnerResetsAndSendsMoney_WhenEverythingIsOk()
        public
        SkipFocker
        RaffleEnterAndTimePassed
    {
        // mock the situation that people enter the raffle,be attention RaffleEnterAndTimePassed has already add the first player
        uint256 previousTimestamp = raffle.getLastTimeStamp();
        uint256 additionalParticipants = 5;
        uint256 startingIndex = 1;
        for (uint256 i = startingIndex; i < startingIndex + additionalParticipants; i++) {
            address participant = address(uint160(i));
            hoax(participant, STARTING_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 prize = entranceFee * (additionalParticipants + 1);
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestId = logs[0].topics[2];
        // because in our test(on anvil),we do not have the real chainlink node,so we need to pretend to be the chainlink node to call the functions that the chainlink node will call.
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));
        // assert the right state after we call the fulfillRandomWords function and pick the winner
        assert(raffle.getRaffleState() == Raffle.RaffleStatus.OPEN);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getNumberOfPlayers() == 0);
        assert(raffle.getLastTimeStamp() > previousTimestamp);
        assert(raffle.getRecentWinner().balance == STARTING_BALANCE - entranceFee + prize);
    }
}
