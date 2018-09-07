pragma solidity ^0.4.24;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-chief/chief.sol";

import "./_polling.sol";
import "./VoteProxy.sol";


contract Voter {
    DSToken gov;
    DSToken iou;
    DSChief chief;
    Polling polling;
    VoteProxy public proxy;

    constructor(DSChief chief_, Polling polling_, DSToken gov_, DSToken iou_) public {
        iou = iou_;
        gov = gov_;
        chief = chief_;
        polling = polling_;
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

    function approveGov(address guy) public {
        gov.approve(guy);
    }

    function approveIou(address guy) public {
        iou.approve(guy);
    }

    function doProxyLock(uint amt, bool _poll) public {
        proxy.lock(amt, _poll);
    }

    function doProxyFree(uint amt, bool _poll) public {
        proxy.free(amt, _poll);
    }

    function doProxyFreeAll(bool _poll) public {
        proxy.freeAll(_poll);
    }

    function doProxyVoteExec(address[] yays) public returns (bytes32 slate) {
        return proxy.voteExec(yays);
    }

    function doProxyVoteExec(bytes32 slate) public {
        proxy.voteExec(slate);
    }

    function doProxyVoteGov(uint256 id, bool yay, bytes logData) public {
        proxy.voteGov(id, yay, logData);
    }
}


contract WarpPolling is Polling {
    uint48 _era; uint32 _age;
    function warp(uint48 era_, uint32 age_) public { _era = era_; _age = age_; }
    function era() public view returns (uint48) { return _era; } 
    function age() public view returns (uint32) { return _age; }       
    constructor(DSToken _gov) public Polling(_gov) {}
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
    WarpPolling polling;

    Voter cold;
    Voter hot;
    Voter random;

    function setUp() public {
        gov = new DSToken("GOV");

        DSChiefFab fab = new DSChiefFab();
        chief = fab.newChief(gov, electionSize);
        iou = chief.IOU();
        polling = new WarpPolling(iou);
        polling.warp(1 hours, 1);

        cold = new Voter(chief, polling, gov, iou);
        hot = new Voter(chief, polling, gov, iou);
        random = new Voter(chief, polling, gov, iou);
        gov.mint(cold, 100 ether);

        proxy = new VoteProxy(chief, polling, cold, hot);

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
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);

        cold.doProxyLock(100 ether, true);
        assertEq(gov.balanceOf(cold), 0 ether);
        assertEq(iou.balanceOf(polling), 100 ether);
        assertEq(gov.balanceOf(chief), 100 ether);

        cold.doProxyFree(100 ether, true);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);
    }

    function test_voting() public {
        cold.approveGov(proxy);
        cold.doProxyLock(100 ether, true);
        polling.warp(2 hours, 2);

        address[] memory yays = new address[](1);
        yays[0] = c1;
        cold.doProxyVoteExec(yays);
        assertEq(chief.approvals(c1), 100 ether);
        assertEq(chief.approvals(c2), 0 ether);

        address[] memory _yays = new address[](1);
        _yays[0] = c2;
        hot.doProxyVoteExec(_yays);
        assertEq(chief.approvals(c1), 0 ether);
        assertEq(chief.approvals(c2), 100 ether);

        uint id = polling.createPoll(1, bytes32(1), 1, 1);
        (, , , uint votesFor_, ) = polling.getPoll(id);
        assertEq(votesFor_, 0 ether);
        cold.doProxyVoteGov(id, true, byts);
        (, , , uint _votesFor, ) = polling.getPoll(id);
        assertEq(_votesFor, 100 ether);
    }

    function test_hot_free() public {
        cold.approveGov(proxy);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);

        cold.doProxyLock(100 ether, true);
        assertEq(gov.balanceOf(cold), 0 ether);
        assertEq(iou.balanceOf(polling), 100 ether);
        assertEq(gov.balanceOf(chief), 100 ether);

        hot.doProxyFree(100 ether, true);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);
    }

    function test_lock_free_no_polling() public {
        cold.approveGov(proxy);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);

        cold.doProxyLock(100 ether, false);
        assertEq(gov.balanceOf(cold), 0 ether);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 100 ether);

        hot.doProxyFree(100 ether, false);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);
    }

    function test_lock_freeAll() public {
        cold.approveGov(proxy);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);

        cold.doProxyLock(10000001000001001, true);
        assertEq(iou.balanceOf(polling), 10000001000001001);
        assertEq(gov.balanceOf(chief), 10000001000001001);

        hot.doProxyFreeAll(true);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);

        cold.doProxyLock(10000001000001001, false);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 10000001000001001);

        hot.doProxyFreeAll(false);
        assertEq(gov.balanceOf(cold), 100 ether);
        assertEq(iou.balanceOf(polling), 0 ether);
        assertEq(gov.balanceOf(chief), 0 ether);
    }

    function testFail_no_polling_yes_polling() public {
        cold.approveGov(proxy);
        cold.doProxyLock(100 ether, false);
        hot.doProxyFree(100 ether, true);
    }

    function testFail_no_proxy_approval() public {
        cold.doProxyLock(100 ether, true);
    }

    function testFail_random_free() public {
        cold.approveGov(proxy);
        cold.doProxyLock(100 ether, true);
        random.doProxyFree(100 ether, true);
    }

    function testFail_random_vote() public {
        cold.approveGov(proxy);
        cold.doProxyLock(100 ether, true);

        address[] memory yays = new address[](1);
        yays[0] = c1;
        random.doProxyVoteExec(yays);
    }
}