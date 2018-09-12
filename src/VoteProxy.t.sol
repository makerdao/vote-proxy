pragma solidity ^0.4.24;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-chief/chief.sol";

import "./VoteProxy.sol";

contract Voter {
    DSChief chief;
    DSToken gov;
    DSToken iou;
    VoteProxy public proxy;

    constructor(DSChief chief_, DSToken gov_, DSToken iou_) public {
        chief = chief_;
        gov = gov_;
        iou = iou_;
    }

    function setProxy(VoteProxy proxy_) public {
        proxy = proxy_;
    }

    function doChiefLock(uint amt) public {
        chief.lock(amt);
    }

    function doChiefFree(uint amt) public {
        chief.free(amt);
    }

    function doTransfer(address guy, uint amt) public {
        gov.transfer(guy, amt);
    }

    function approveGov(address guy) public {
        gov.approve(guy);
    }

    function approveIou(address guy) public {
        iou.approve(guy);
    }

    function doProxyLock(uint amt) public {
        proxy.lock(amt);
    }

    function doProxyFree(uint amt) public {
        proxy.free(amt);
    }

    function doProxyFreeAll() public {
        proxy.freeAll();
    }

    function doProxyVote(address[] yays) public returns (bytes32 slate) {
        return proxy.vote(yays);
    }

    function doProxyVote(bytes32 slate) public {
        proxy.vote(slate);
    }
}

contract VoteProxyTest is DSTest {
    uint256 constant electionSize = 3;
    address constant c1 = 0x1;
    address constant c2 = 0x2;
    bytes byts;

    VoteProxy proxy;
    DSToken gov;
    DSToken iou;
    DSChief chief;

    Voter cold;
    Voter hot;
    Voter random;

    function setUp() public {
        gov = new DSToken("GOV");

        DSChiefFab fab = new DSChiefFab();
        chief = fab.newChief(gov, electionSize);
        iou = chief.IOU();

        cold = new Voter(chief, gov, iou);
        hot = new Voter(chief, gov, iou);
        random = new Voter(chief, gov, iou);
        gov.mint(cold, 100 ether);

        proxy = new VoteProxy(chief, cold, hot);

        random.setProxy(proxy);
        cold.setProxy(proxy);
        hot.setProxy(proxy);
    }

    // sainity test -> cold can lock and free gov tokens with chief directly
    function test_chief_lock_free() public {
        cold.approveGov(chief);
        cold.approveIou(chief);

        cold.doChiefLock(100 ether);
        assertEq(gov.balanceOf(cold), 0);
        assertEq(gov.balanceOf(chief), 100 ether);

        cold.doChiefFree(100 ether);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(gov.balanceOf(chief), 0 ether);
    }

    function test_cold_lock_free() public {
        cold.approveGov(proxy);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(gov.balanceOf(chief), 0 ether);

        cold.doProxyLock(100 ether);
        assertEq(gov.balanceOf(cold), 0 ether);
        assertEq(gov.balanceOf(chief), 100 ether);

        cold.doProxyFree(100 ether);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(gov.balanceOf(chief), 0 ether);
    }

    function test_hot_cold_voting() public {
        cold.approveGov(proxy);
        cold.doProxyLock(100 ether);

        address[] memory yays = new address[](1);
        yays[0] = c1;
        cold.doProxyVote(yays);
        assertEq(chief.approvals(c1), 100 ether);
        assertEq(chief.approvals(c2), 0 ether);

        address[] memory _yays = new address[](1);
        _yays[0] = c2;
        hot.doProxyVote(_yays);
        assertEq(chief.approvals(c1), 0 ether);
        assertEq(chief.approvals(c2), 100 ether);
    }

    function test_hot_free() public {
        cold.approveGov(proxy);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(gov.balanceOf(chief), 0 ether);

        cold.doProxyLock(100 ether);
        assertEq(gov.balanceOf(cold), 0 ether);
        assertEq(gov.balanceOf(chief), 100 ether);

        hot.doProxyFree(100 ether);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(gov.balanceOf(chief), 0 ether);
    }

    function test_lock_free() public {
        cold.approveGov(proxy);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(gov.balanceOf(chief), 0 ether);

        cold.doProxyLock(100 ether);
        assertEq(gov.balanceOf(cold), 0 ether);
        assertEq(gov.balanceOf(chief), 100 ether);

        hot.doProxyFree(100 ether);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(gov.balanceOf(chief), 0 ether);
    }

    function test_free_all() public {
        cold.approveGov(proxy);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(gov.balanceOf(chief), 0 ether);

        cold.doProxyLock(50 ether);
        cold.doTransfer(proxy, 25 ether);
        assertEq(gov.balanceOf(cold), 25 ether);
        assertEq(gov.balanceOf(proxy), 25 ether);
        assertEq(gov.balanceOf(chief), 50 ether);

        cold.doProxyFreeAll();
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(gov.balanceOf(proxy), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);
    }

    function testFail_no_proxy_approval() public {
        cold.doProxyLock(100 ether);
    }

    function testFail_random_free() public {
        cold.approveGov(proxy);
        cold.doProxyLock(100 ether);
        random.doProxyFree(100 ether);
    }

    function testFail_random_vote() public {
        cold.approveGov(proxy);
        cold.doProxyLock(100 ether);

        address[] memory yays = new address[](1);
        yays[0] = c1;
        random.doProxyVote(yays);
    }
}
