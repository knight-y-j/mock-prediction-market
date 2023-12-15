// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MockPredictionMarket} from "src/MockPredictionMarket/MockPredictionMarket.sol";

contract TestMockPredictionMarket is Test {
    MockPredictionMarket pm;
    address owner;
    address buyer;
    address seller;
    address dummyActor;
    uint256 periodTime;
    uint256 balance;
    uint256 shareOfPrice;
    uint256 amount;
    uint256 orderID;

    function setUp() public {
        owner = makeAddr("Queen");
        buyer = makeAddr("Rabbit");
        seller = makeAddr("Knight");
        dummyActor = makeAddr("King");
        periodTime = 1 days;
        balance = 2000 wei;
        shareOfPrice = 100 wei;
        amount = 10 wei;

        vm.deal(owner, balance);
        vm.deal(buyer, balance);
        vm.deal(seller, balance);

        vm.prank(owner);
        pm = new MockPredictionMarket{value: 500 wei}(periodTime);
    }

    function test_OK_MockPredictionMarket_depositToPredictionMarket_bySeller()
        public
    {
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(seller);
        isDone = pm.depositToPredictionMarket{value: 300 wei}();

        assertTrue(isDone);

        vm.stopPrank();
    }

    function test_NG_MockPredictionMarket_depositToPredictionMarket_byOwner()
        public
    {
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(owner);
        vm.expectRevert(bytes("caller is only depositor"));
        isDone = pm.depositToPredictionMarket{value: 100 wei}();

        assertTrue(!isDone);

        vm.stopPrank();
    }

    function test_OK_MockPredictionMarket_buyOrder_byBuyer() public {
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(buyer);
        isDone = pm.buyOrder{value: 100 wei}(shareOfPrice);

        assertTrue(isDone);

        vm.stopPrank();
    }

    function test_NG_MockPredictionMarket_buyOrder_byOwner() public {
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(owner);
        vm.expectRevert(bytes("caller is only depositor"));
        isDone = pm.buyOrder{value: 100 wei}(shareOfPrice);

        assertTrue(!isDone);

        vm.stopPrank();
    }

    function test_OK_MockPredictionMarket_sellOrder_bySeller() public {
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(seller);

        // 1. deposit to prediction market
        isDone = pm.depositToPredictionMarket{value: 1000 wei}();
        assertTrue(isDone);

        // 2. order sell
        isDone = pm.sellOrder(shareOfPrice, amount);
        assertTrue(isDone);

        vm.stopPrank();
    }

    function test_NG_MockPredictionMarket_sellOrder_byOwner() public {
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(owner);
        vm.expectRevert(bytes("caller is only depositor"));
        isDone = pm.sellOrder(shareOfPrice, 10 wei);

        assertTrue(!isDone);

        vm.stopPrank();
    }

    function test_OK_MockPredictionMarket_buyTrade_byBuyer() public {
        orderID = 2;
        bool isDone;
        assertTrue(!isDone);

        /// 1. order buy by buyer
        vm.prank(buyer);
        isDone = pm.buyOrder{value: 100 wei}(shareOfPrice);

        assertTrue(isDone);

        /// 2. deposit to prediction market
        vm.startPrank(seller);

        isDone = pm.depositToPredictionMarket{value: 1000 wei}();
        assertTrue(isDone);

        /// 3. order sell by seller
        isDone = pm.sellOrder(shareOfPrice, amount);
        assertTrue(isDone);

        vm.stopPrank();

        /// 4. trade buy by buyer
        vm.prank(buyer);
        isDone = pm.buyTrade{value: 10 wei}(orderID);

        assertTrue(isDone);
    }

    function test_NG_MockPredictionMarket_buyTrade_byOwner() public {
        uint256 dummyOrderID = 1;
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(owner);
        vm.expectRevert(bytes("caller is only depositor"));
        isDone = pm.buyTrade{value: 10 wei}(dummyOrderID);

        assertTrue(!isDone);

        vm.stopPrank();
    }

    function test_OK_MockPredictionMarket_sellTrade_bySeller() public {
        orderID = 1;
        bool isDone;
        assertTrue(!isDone);

        /// 1. order buy by buyer
        vm.prank(buyer);
        isDone = pm.buyOrder{value: 100 wei}(shareOfPrice);

        assertTrue(isDone);

        /// 2. trade sell by seller
        vm.startPrank(seller);
        isDone = pm.depositToPredictionMarket{value: 1000 wei}();
        assertTrue(isDone);

        /// 3. trade sell by seller
        isDone = pm.sellTrade(orderID, amount);
        assertTrue(isDone);

        vm.stopPrank();
    }

    function test_NG_MockPredictionMarket_sellTrade_byOwner() public {
        uint256 dummyOrderID = 1;
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(owner);
        vm.expectRevert(bytes("caller is only depositor"));
        isDone = pm.sellTrade(dummyOrderID, amount);

        assertTrue(!isDone);

        vm.stopPrank();
    }

    function test_OK_MockPredictionMarket_cancelOrder_byBuyer() public {
        orderID = 1;
        bool isDone;
        assertTrue(!isDone);

        /// 1. order buy by buyer
        vm.startPrank(buyer);
        isDone = pm.buyOrder{value: 100 wei}(shareOfPrice);
        assertTrue(isDone);

        /// 2. cancel order by buyer
        isDone = pm.cancelOrder(orderID);
        assertTrue(isDone);

        vm.stopPrank();
    }

    function test_OK_MockPredictionMarket_cancelOrder_bySeller() public {
        orderID = 1;
        bool isDone;
        assertTrue(!isDone);

        /// 1. deposit to prediction maeket by seller
        vm.startPrank(seller);
        isDone = pm.depositToPredictionMarket{value: 1000 wei}();
        assertTrue(isDone);

        /// 2. order sell by seller
        isDone = pm.sellOrder(shareOfPrice, amount);
        assertTrue(isDone);

        /// 3. cancel order by seller
        isDone = pm.cancelOrder(orderID);
        assertTrue(isDone);

        vm.stopPrank();
    }

    function test_NG_MockPredictionMarket_cancelOrder_bySeller() public {
        orderID = 1;
        bool isDone;
        assertTrue(!isDone);

        /// 1. order buy by buyer
        vm.prank(buyer);
        isDone = pm.buyOrder{value: 100 wei}(shareOfPrice);
        assertTrue(isDone);

        /// 2. cancel order by buyer
        vm.prank(seller);
        vm.expectRevert(bytes("caller is only orderer"));
        isDone = pm.cancelOrder(orderID);

        assertTrue(!isDone);
    }

    function test_OK_MockPredictionMarket_resolvePredictionMarket_TRUE_byOwner()
        public
    {
        bool dummyPredictionResult = true;
        uint256 dummyDateTimestamp = 2 days;
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(owner);
        vm.warp(dummyDateTimestamp);
        isDone = pm.resolvePredictionMarket(dummyPredictionResult);

        assertTrue(isDone);

        vm.stopPrank();
    }

    function test_OK_MockPredictionMarket_resolvePredictionMarket_FALSE_byOwner()
        public
    {
        bool dummyPredictionResult = false;
        uint256 dummyDateTimestamp = 2 days;
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(owner);
        vm.warp(dummyDateTimestamp);
        isDone = pm.resolvePredictionMarket(dummyPredictionResult);

        assertTrue(isDone);

        vm.stopPrank();
    }

    function test_NG_MockPredictionMarket_resolvePredictionMarket_byBuyer()
        public
    {
        bool dummyPredictionResult = true;
        uint256 dummyDateTimestamp = 2 days;
        bool isDone;
        assertTrue(!isDone);

        vm.startPrank(buyer);
        vm.warp(dummyDateTimestamp);
        vm.expectRevert(bytes("caller is only owner"));
        isDone = pm.resolvePredictionMarket(dummyPredictionResult);

        assertTrue(!isDone);

        vm.stopPrank();
    }

    function test_OK_MockPredictionMarket_withdraw_FALSE_byOwner() public {
        bool dummyPredictionResult = false;
        uint256 dummyDateTimestamp = 2 days;
        bool isDone;
        assertTrue(!isDone);

        /// 1. resolve prediction market by owner
        vm.startPrank(owner);
        vm.warp(dummyDateTimestamp);
        isDone = pm.resolvePredictionMarket(dummyPredictionResult);
        assertTrue(isDone);

        /// 2. withdraw prediction market contract by owner
        isDone = pm.withdraw();

        assertTrue(isDone);

        vm.stopPrank();
    }
}
