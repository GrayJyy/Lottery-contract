// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
// import {Vm} from "forge-std/Vm.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    constructor() {}

    event EnterRaffle(address indexed participant);

    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 interval;
    uint256 entranceFee;

    address public player = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        vm.deal(player, STARTING_BALANCE);
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (,, interval, entranceFee,,,,) = helperConfig.activeNetworkConfig();
    }

    /**
     * @dev test enterRaffle
     */
    function testRaffle_ShouldInOpenState_WhenInitializes() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleStatus.OPEN);
    }

    function testRaffle_ShouldReverts_WhenPaymentIsNotEnough() public {
        vm.prank(player);
        vm.expectRevert(Raffle.Raffle__NotEnoughFee.selector);
        raffle.enterRaffle();
    }

    function testRaffle_ShouldRecordsPlayers_WhenTheyEnter() public {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == player);
    }

    function testRaffle_ShouldEmitsEvent_WhenEnterSuccessfully() public {
        vm.prank(player);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnterRaffle(player);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRaffle_ShouldRefusesEnter_WhenCalculating() public {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
    }
}
