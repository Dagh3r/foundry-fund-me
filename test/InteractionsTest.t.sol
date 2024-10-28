// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test{

    uint256 constant AMOUNT_TO_SEND = 0.1 ether; //100000000000000000
    uint256 constant GAS = 1;
    address USER = makeAddr('Certified Weeb');
    FundMe fundMe;

    function setUp() external{
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, 1e18);
    }

    function testUserCanFundInteractions() public{
        console.log(USER);
        console.log(address(USER).balance);

        FundFundMe fundFundMe = new FundFundMe();
        console.log("address of fundFundMe:", address(fundFundMe));
        vm.deal(USER, 1e18);
        vm.startPrank(USER);
        fundFundMe.fundFundMe(address(fundMe));
        vm.stopPrank();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOwnerCanWithdraw() public{
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);

    }
}