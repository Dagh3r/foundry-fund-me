// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    uint256 constant AMOUNT_TO_SEND = 0.1 ether; //100000000000000000
    uint256 constant GAS = 1;
    address USER = makeAddr('niggas');
    FundMe fundMe;
    DeployFundMe deployFundMe;
    function setUp() external{
        deployFundMe = new DeployFundMe();
        vm.deal(USER, 100 ether);
        fundMe = deployFundMe.run();
    }
    modifier fund(){
        vm.prank(USER);
        fundMe.fund{value: AMOUNT_TO_SEND}();
        _;
    }
    function testMinimuUSD() public view{ 
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }
    function testOwnerIsMsgSender() public view {
        console.log(msg.sender);
        address owner = fundMe.getOwner();
        console.log(owner);
        assertEq(owner, msg.sender);
    }

    function testPriceFeedVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughETH()public {
        vm.expectRevert();
        fundMe.fund();
    }
    function testFundsUpdatesFundedDataStructure() public fund{
        uint256 amountFunded = fundMe.getAddressToAmountFunder(USER);
        assertEq(amountFunded, AMOUNT_TO_SEND);
    }

    function testAddsFundersToArrayOfFunders() public fund{
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public fund{
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public{
        //Use this methodology, proff uses it you should too
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingGas = gasleft();
        //Act
        vm.txGasPrice(GAS);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 endingGas = gasleft();
        console.log((startingGas - endingGas) * tx.gasprice);
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance+startingFundMeBalance);

    }

    function testWithdrawFromMultipleFunders() public fund{
        //Arrange
        uint160 numberOfFunder = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i <numberOfFunder; i++){
            hoax(address(i), AMOUNT_TO_SEND);
            fundMe.fund{value: AMOUNT_TO_SEND}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testCheaperWithdrawFromMultipleFunders() public fund{
        //Arrange
        uint160 numberOfFunder = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i <numberOfFunder; i++){
            hoax(address(i), AMOUNT_TO_SEND);
            fundMe.fund{value: AMOUNT_TO_SEND}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}