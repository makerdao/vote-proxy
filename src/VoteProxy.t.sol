pragma solidity ^0.4.21;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-chief/chief.sol";

import "./VoteProxy.sol";

contract ChiefUser {
    DSToken gov;
    DSToken iou;
    DSChief chief;
    VoteProxy proxy;

    function ChiefUser(DSToken gov_, DSToken iou_, DSChief chief_) public {
        iou = iou_;
        gov = gov_;
        chief = chief_;
    }

    function setProxy(VoteProxy proxy_) public {
        proxy = proxy_;
    }

    function doTransfer(address to, uint amt) public {
        gov.transfer(to, amt);
    }

    function doApprove(uint amt) public {
        gov.approve(chief, amt);
        iou.approve(chief, amt);
    }

    function doProxyLock(uint amt) public {
        proxy.lock(amt);
    }

    function doProxyFree(uint amt) public {
        proxy.free(amt);
    }

    function doProxyApprove(uint amt) public {
        proxy.approve(amt);
    }

    function doLock(uint amt) public {
        chief.lock(amt);
    }

    function doFree(uint amt) public {
        chief.free(amt);
    }

    function doWithdraw(uint amt) public {
        proxy.withdraw(amt);
    }

    function doProxyUnlockWithdrawAll() public {
        proxy.unlockWithdrawAll();
    }

    function doProxyUnlockWithdraw(uint amt) public {
        proxy.unlockWithdraw(amt);
    }

    function doProxyVote(address[] yays) public returns (bytes32 slate) {
        return proxy.vote(yays);
    }

    function doProxyEtch(address[] yays) public returns (bytes32 slate) {
        return proxy.etch(yays);
    }

    function doProxyVote(bytes32 slate) public {
        return proxy.vote(slate);
    }
}

contract VoteProxyTest is DSTest {
    uint256 constant initialBalance = 1000 ether;
    uint256 constant electionSize = 3;

    address constant c1 = 0x1;

    VoteProxy proxy;
    DSToken gov;
    DSToken iou;
    DSChief chief;

    ChiefUser cold;
    ChiefUser hot;
    ChiefUser random;

    function setUp() public {
        gov = new DSToken("GOV");
        gov.mint(initialBalance);

        DSChiefFab fab = new DSChiefFab();
        chief = fab.newChief(gov, electionSize);
        iou = chief.IOU();

        cold = new ChiefUser(gov, iou, chief);
        hot  = new ChiefUser(gov, iou, chief);
        random  = new ChiefUser(gov, iou, chief);

        gov.transfer(cold, 100 ether);

        proxy = new VoteProxy(chief, cold, hot);

        cold.setProxy(proxy);
        hot.setProxy(proxy);
    }

    // sainity test
    // cold can lock and free gov tokens
    function test_lock_free() public {
      // approve 100 ether
      cold.doApprove(100 ether);
      // lock 100 ether
      cold.doLock(100 ether);

      // user should have a balance of 0 ether
      // and DSChief should have a balance of 100 ether
      require(gov.balanceOf(cold) == 0);
      require(gov.balanceOf(chief) == 100 ether);

      // free 100 ether
      cold.doFree(100 ether);

      // cold should have a balance of 100 ether
      require(gov.balanceOf(cold) == 100 ether);
      require(gov.balanceOf(chief) == 0 ether);

    }

    function test_cold_lock_free() public {
      require(gov.balanceOf(cold) == 100 ether);
      require(gov.balanceOf(proxy) == 0);
      require(gov.balanceOf(chief) == 0);

      cold.doTransfer(proxy, 100 ether);
      require(gov.balanceOf(cold) == 0);
      require(gov.balanceOf(proxy) == 100 ether);
      require(gov.balanceOf(chief) == 0);

      cold.doProxyLock(100 ether);
      require(gov.balanceOf(cold) == 0);
      require(gov.balanceOf(proxy) == 0);
      require(gov.balanceOf(chief) == 100 ether);

      cold.doProxyFree(100 ether);
      require(gov.balanceOf(cold) == 0);
      require(gov.balanceOf(proxy) == 100 ether);
      require(gov.balanceOf(chief) == 0);

      cold.doWithdraw(100 ether);
      require(gov.balanceOf(cold) == 100 ether);
      require(gov.balanceOf(proxy) == 0);
      require(gov.balanceOf(chief) == 0);
    }

    function test_hot_lock_free() public {
      require(gov.balanceOf(cold) == 100 ether);
      require(gov.balanceOf(proxy) == 0);
      require(gov.balanceOf(chief) == 0);

      cold.doTransfer(proxy, 100 ether);
      require(gov.balanceOf(cold) == 0);
      require(gov.balanceOf(proxy) == 100 ether);
      require(gov.balanceOf(chief) == 0);

      hot.doProxyLock(100 ether);
      require(gov.balanceOf(cold) == 0);
      require(gov.balanceOf(proxy) == 0);
      require(gov.balanceOf(chief) == 100 ether);

      hot.doProxyFree(100 ether);
      require(gov.balanceOf(cold) == 0);
      require(gov.balanceOf(proxy) == 100 ether);
      require(gov.balanceOf(chief) == 0);

      hot.doWithdraw(100 ether);
      require(gov.balanceOf(cold) == 100 ether);
      require(gov.balanceOf(proxy) == 0);
      require(gov.balanceOf(chief) == 0);
    }

    function test_hot_proxy_voting_etch() public {
      // setup
      cold.doTransfer(proxy, 100 ether);
      cold.doProxyLock(100 ether);

      address[] memory uLargeSlate = new address[](1);
      uLargeSlate[0] = c1;
      bytes32 slate = hot.doProxyEtch(uLargeSlate);
      hot.doProxyVote(slate);
      require(chief.approvals(c1) == 100 ether);
    }

    function test_cold_proxy_voting_etch() public {
      // setup
      cold.doTransfer(proxy, 100 ether);
      cold.doProxyLock(100 ether);

      address[] memory uLargeSlate = new address[](1);
      uLargeSlate[0] = c1;
      bytes32 slate = cold.doProxyEtch(uLargeSlate);
      cold.doProxyVote(slate);
      require(chief.approvals(c1) == 100 ether);
    }

    function test_hot_proxy_voting_array() public {
      // setup
      cold.doTransfer(proxy, 100 ether);
      cold.doProxyLock(100 ether);

      address[] memory uLargeSlate = new address[](1);
      uLargeSlate[0] = c1;
      hot.doProxyVote(uLargeSlate);
      require(chief.approvals(c1) == 100 ether);
    }

    function test_cold_proxy_voting_array() public {
      // setup
      cold.doTransfer(proxy, 100 ether);
      cold.doProxyLock(100 ether);

      address[] memory uLargeSlate = new address[](1);
      uLargeSlate[0] = c1;
      cold.doProxyVote(uLargeSlate);
      require(chief.approvals(c1) == 100 ether);
    }

    function test_unlock_withdraw_all() public {
      // setup
      cold.doTransfer(proxy, 100 ether);
      cold.doProxyLock(50 ether);

      cold.doProxyUnlockWithdrawAll();
      require(gov.balanceOf(cold) == 100 ether);
      require(gov.balanceOf(proxy) == 0);
    }

    function test_unlock_withdraw() public {
      // setup
      cold.doTransfer(proxy, 100 ether);
      cold.doProxyLock(50 ether);

      cold.doProxyUnlockWithdraw(75 ether);
      require(gov.balanceOf(cold) == 75 ether);
      require(gov.balanceOf(proxy) == 0 ether);
      require(chief.deposits(proxy) == 25 ether);
    }

    function testFail_no_proxy_approval() public {
      cold.doTransfer(proxy, 100 ether);
      cold.doProxyApprove(0);
      cold.doProxyLock(100 ether);
    }

    function testFail_random_withdrawal() public {
      cold.doTransfer(proxy, 100 ether);
      require(gov.balanceOf(cold) == 0);
      require(gov.balanceOf(proxy) == 100 ether);

      random.doWithdraw(100 ether);
    }

    function testFail_random_vote() public {
      // setup
      cold.doTransfer(proxy, 100 ether);
      cold.doProxyLock(100 ether);

      address[] memory uLargeSlate = new address[](1);
      uLargeSlate[0] = c1;
      random.doProxyVote(uLargeSlate);
      require(chief.approvals(c1) == 100 ether);
    }
}
