// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    
    // Test constants
    uint256 public constant INITIAL_SUPPLY = 1000 ether;
    uint256 public constant TRANSFER_AMOUNT = 100 ether;
    
    // Test addresses
    address public deployer = makeAddr("deployer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        vm.prank(deployer);
        ourToken = new OurToken(INITIAL_SUPPLY);
    }

    /*//////////////////////////////////////////////////////////////
                           BASIC TOKEN PROPERTIES
    //////////////////////////////////////////////////////////////*/

    function testTokenName() public view {
        assertEq(ourToken.name(), "OurToken");
    }

    function testTokenSymbol() public view {
        assertEq(ourToken.symbol(), "OT");
    }

    function testTokenDecimals() public view {
        assertEq(ourToken.decimals(), 18);
    }

    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), INITIAL_SUPPLY);
    }

    function testDeployerInitialBalance() public view {
        assertEq(ourToken.balanceOf(deployer), INITIAL_SUPPLY);
    }

    function testOtherAddressesHaveZeroBalance() public view {
        assertEq(ourToken.balanceOf(alice), 0);
        assertEq(ourToken.balanceOf(bob), 0);
        assertEq(ourToken.balanceOf(charlie), 0);
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testConstructorMintsToDeployer() public {
        vm.prank(alice);
        OurToken newToken = new OurToken(500 ether);
        
        assertEq(newToken.totalSupply(), 500 ether);
        assertEq(newToken.balanceOf(alice), 500 ether);
    }

    function testConstructorWithZeroSupply() public {
        vm.prank(bob);
        OurToken newToken = new OurToken(0);
        
        assertEq(newToken.totalSupply(), 0);
        assertEq(newToken.balanceOf(bob), 0);
    }

    function testConstructorWithMaxSupply() public {
        uint256 maxSupply = type(uint256).max;
        vm.prank(charlie);
        OurToken newToken = new OurToken(maxSupply);
        
        assertEq(newToken.totalSupply(), maxSupply);
        assertEq(newToken.balanceOf(charlie), maxSupply);
    }

    /*//////////////////////////////////////////////////////////////
                           TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function testTransferSuccess() public {
        vm.prank(deployer);
        bool success = ourToken.transfer(alice, TRANSFER_AMOUNT);
        
        assertTrue(success);
        assertEq(ourToken.balanceOf(deployer), INITIAL_SUPPLY - TRANSFER_AMOUNT);
        assertEq(ourToken.balanceOf(alice), TRANSFER_AMOUNT);
    }

    function testTransferEmitsEvent() public {
        vm.prank(deployer);
        
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(deployer, alice, TRANSFER_AMOUNT);
        
        ourToken.transfer(alice, TRANSFER_AMOUNT);
    }

    function testTransferToSelf() public {
        uint256 initialBalance = ourToken.balanceOf(deployer);
        
        vm.prank(deployer);
        bool success = ourToken.transfer(deployer, TRANSFER_AMOUNT);
        
        assertTrue(success);
        assertEq(ourToken.balanceOf(deployer), initialBalance);
    }

    function testTransferZeroAmount() public {
        uint256 initialDeployerBalance = ourToken.balanceOf(deployer);
        uint256 initialAliceBalance = ourToken.balanceOf(alice);
        
        vm.prank(deployer);
        bool success = ourToken.transfer(alice, 0);
        
        assertTrue(success);
        assertEq(ourToken.balanceOf(deployer), initialDeployerBalance);
        assertEq(ourToken.balanceOf(alice), initialAliceBalance);
    }

    function testTransferInsufficientBalance() public {
        vm.prank(alice); // Alice has 0 balance
        vm.expectRevert();
        ourToken.transfer(bob, 1 ether);
    }

    function testTransferToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert();
        ourToken.transfer(address(0), TRANSFER_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                           APPROVAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testApproveSuccess() public {
        vm.prank(deployer);
        bool success = ourToken.approve(alice, TRANSFER_AMOUNT);
        
        assertTrue(success);
        assertEq(ourToken.allowance(deployer, alice), TRANSFER_AMOUNT);
    }

    function testApproveEmitsEvent() public {
        vm.prank(deployer);
        
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval(deployer, alice, TRANSFER_AMOUNT);
        
        ourToken.approve(alice, TRANSFER_AMOUNT);
    }

    function testApproveZeroAmount() public {
        // First approve some amount
        vm.prank(deployer);
        ourToken.approve(alice, TRANSFER_AMOUNT);
        assertEq(ourToken.allowance(deployer, alice), TRANSFER_AMOUNT);
        
        // Then approve zero to reset
        vm.prank(deployer);
        bool success = ourToken.approve(alice, 0);
        
        assertTrue(success);
        assertEq(ourToken.allowance(deployer, alice), 0);
    }

    function testApproveOverwritesPreviousAllowance() public {
        vm.prank(deployer);
        ourToken.approve(alice, TRANSFER_AMOUNT);
        assertEq(ourToken.allowance(deployer, alice), TRANSFER_AMOUNT);
        
        vm.prank(deployer);
        ourToken.approve(alice, TRANSFER_AMOUNT * 2);
        assertEq(ourToken.allowance(deployer, alice), TRANSFER_AMOUNT * 2);
    }

    function testApproveToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert();
        ourToken.approve(address(0), TRANSFER_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                           TRANSFERFROM TESTS
    //////////////////////////////////////////////////////////////*/

    function testTransferFromSuccess() public {
        // Setup: deployer approves alice to spend tokens
        vm.prank(deployer);
        ourToken.approve(alice, TRANSFER_AMOUNT);
        
        // Alice transfers from deployer to bob
        vm.prank(alice);
        bool success = ourToken.transferFrom(deployer, bob, TRANSFER_AMOUNT);
        
        assertTrue(success);
        assertEq(ourToken.balanceOf(deployer), INITIAL_SUPPLY - TRANSFER_AMOUNT);
        assertEq(ourToken.balanceOf(bob), TRANSFER_AMOUNT);
        assertEq(ourToken.allowance(deployer, alice), 0);
    }

    function testTransferFromEmitsEvent() public {
        vm.prank(deployer);
        ourToken.approve(alice, TRANSFER_AMOUNT);
        
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(deployer, bob, TRANSFER_AMOUNT);
        
        ourToken.transferFrom(deployer, bob, TRANSFER_AMOUNT);
    }

    function testTransferFromPartialAllowance() public {
        uint256 approvedAmount = TRANSFER_AMOUNT * 2;
        uint256 transferAmount = TRANSFER_AMOUNT;
        
        vm.prank(deployer);
        ourToken.approve(alice, approvedAmount);
        
        vm.prank(alice);
        ourToken.transferFrom(deployer, bob, transferAmount);
        
        assertEq(ourToken.balanceOf(bob), transferAmount);
        assertEq(ourToken.allowance(deployer, alice), approvedAmount - transferAmount);
    }

    function testTransferFromInsufficientAllowance() public {
        vm.prank(deployer);
        ourToken.approve(alice, TRANSFER_AMOUNT);
        
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(deployer, bob, TRANSFER_AMOUNT + 1);
    }

    function testTransferFromInsufficientBalance() public {
        // Give alice some tokens but not enough
        vm.prank(deployer);
        ourToken.transfer(alice, 50 ether);
        
        // Alice approves bob to spend more than she has
        vm.prank(alice);
        ourToken.approve(bob, 100 ether);
        
        // Bob tries to transfer more than alice has
        vm.prank(bob);
        vm.expectRevert();
        ourToken.transferFrom(alice, charlie, 100 ether);
    }

    function testTransferFromZeroAllowance() public {
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(deployer, bob, TRANSFER_AMOUNT);
    }

    function testTransferFromToZeroAddress() public {
        vm.prank(deployer);
        ourToken.approve(alice, TRANSFER_AMOUNT);
        
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(deployer, address(0), TRANSFER_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                           FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzTransfer(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY);
        
        vm.prank(deployer);
        bool success = ourToken.transfer(alice, amount);
        
        assertTrue(success);
        assertEq(ourToken.balanceOf(alice), amount);
        assertEq(ourToken.balanceOf(deployer), INITIAL_SUPPLY - amount);
    }

    function testFuzzApprove(uint256 amount) public {
        vm.prank(deployer);
        bool success = ourToken.approve(alice, amount);
        
        assertTrue(success);
        assertEq(ourToken.allowance(deployer, alice), amount);
    }

    function testFuzzTransferFrom(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY);
        
        vm.prank(deployer);
        ourToken.approve(alice, amount);
        
        vm.prank(alice);
        bool success = ourToken.transferFrom(deployer, bob, amount);
        
        assertTrue(success);
        assertEq(ourToken.balanceOf(bob), amount);
        assertEq(ourToken.balanceOf(deployer), INITIAL_SUPPLY - amount);
    }

    /*//////////////////////////////////////////////////////////////
                           INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/

    function invariant_totalSupplyNeverChanges() public view {
        assertEq(ourToken.totalSupply(), INITIAL_SUPPLY);
    }

    function invariant_balancesSumToTotalSupply() public view {
        uint256 totalBalance = ourToken.balanceOf(deployer) + 
                              ourToken.balanceOf(alice) + 
                              ourToken.balanceOf(bob) + 
                              ourToken.balanceOf(charlie);
        assertEq(totalBalance, INITIAL_SUPPLY);
    }

    /*//////////////////////////////////////////////////////////////
                           INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testComplexTransferScenario() public {
        // Deployer transfers to alice
        vm.prank(deployer);
        ourToken.transfer(alice, 300 ether);
        
        // Alice approves bob to spend 100 ether
        vm.prank(alice);
        ourToken.approve(bob, 100 ether);
        
        // Bob transfers 50 ether from alice to charlie
        vm.prank(bob);
        ourToken.transferFrom(alice, charlie, 50 ether);
        
        // Verify final balances
        assertEq(ourToken.balanceOf(deployer), 700 ether);
        assertEq(ourToken.balanceOf(alice), 250 ether);
        assertEq(ourToken.balanceOf(bob), 0);
        assertEq(ourToken.balanceOf(charlie), 50 ether);
        assertEq(ourToken.allowance(alice, bob), 50 ether);
    }
}

// Import IERC20 interface for event testing
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";






