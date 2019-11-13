pragma solidity >=0.4.24;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-chief/chief.sol";

import "./VoteProxyMultiSig.sol";

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

    function doProxyVote(address[] memory yays) public returns (bytes32 slate) {
        return proxy.vote(yays);
    }

    function doProxyVote(bytes32 slate) public {
        proxy.vote(slate);
    }

    function enableProxy() public {
        proxy.enable();
    }

    function disableProxy() public {
        proxy.disable();
    }
}

contract VoteProxyTest is DSTest {
    uint256 constant electionSize = 3;
    address constant c1 = address(0x1);
    address constant c2 = address(0x2);
    bytes byts;

    VoteProxy proxy;
    DSToken gov;
    DSToken iou;
    DSChief chief;

    Voter cold;
    Voter mgmt;
    address[] _mgmt;
    Voter tech;
    address[] _tech;
    Voter random;

    function setUp() public {
        gov = new DSToken("GOV");

        DSChiefFab fab = new DSChiefFab();
        chief = fab.newChief(gov, electionSize);
        iou = chief.IOU();

        cold = new Voter(chief, gov, iou);
        mgmt = new Voter(chief, gov, iou);
        _mgmt.push(mgmt);
        tech = new Voter(chief, gov, iou);
        _tech.push(tech);
        random = new Voter(chief, gov, iou);
        gov.mint(address(cold), 100 ether);

        proxy = new VoteProxy(chief, address(cold), _mgmt, _tech);

        random.setProxy(proxy);
        cold.setProxy(proxy);
        mgmt.setProxy(proxy);
        tech.setProxy(proxy);
    }

    // sainity test -> cold can lock and free gov tokens with chief directly
    function test_chief_lock_free() public {
        cold.approveGov(address(chief));
        cold.approveIou(address(chief));

        cold.doChiefLock(100 ether);
        assertEq(gov.balanceOf(address(cold)), 0);
        assertEq(gov.balanceOf(address(chief)), 100 ether);

        cold.doChiefFree(100 ether);
        assertEq(gov.balanceOf(address(cold)), 100 ether);
        assertEq(gov.balanceOf(address(chief)), 0 ether);
    }

    function test_cold_lock_free() public {
        cold.approveGov(address(proxy));
        assertEq(gov.balanceOf(address(cold)), 100 ether);
        assertEq(gov.balanceOf(address(chief)), 0 ether);

        cold.doProxyLock(100 ether);
        assertEq(gov.balanceOf(address(cold)), 0 ether);
        assertEq(gov.balanceOf(address(chief)), 100 ether);

        cold.doProxyFree(100 ether);
        assertEq(gov.balanceOf(address(cold)), 100 ether);
        assertEq(gov.balanceOf(address(chief)), 0 ether);
    }

    function test_tech_voting() public {
        cold.approveGov(address(proxy));
        cold.doProxyLock(100 ether);

        hot.enableProxy();

        address[] memory yays = new address[](1);
        yays[0] = c1;
        tech.doProxyVote(yays);
        assertEq(chief.approvals(c1), 100 ether);
        assertEq(chief.approvals(c2), 0 ether);
        assertEq(proxy.live, 0);
    }

    function test_mgmt_free() public {
        cold.approveGov(address(proxy));
        assertEq(gov.balanceOf(address(cold)), 100 ether);
        assertEq(gov.balanceOf(address(chief)), 0 ether);

        cold.doProxyLock(100 ether);
        assertEq(gov.balanceOf(address(cold)), 0 ether);
        assertEq(gov.balanceOf(address(chief)), 100 ether);

        mgmt.doProxyFree(100 ether);
        assertEq(gov.balanceOf(address(cold)), 100 ether);
        assertEq(gov.balanceOf(address(chief)), 0 ether);
    }

    function test_tech_free() public {
        cold.approveGov(address(proxy));
        assertEq(gov.balanceOf(address(cold)), 100 ether);
        assertEq(gov.balanceOf(address(chief)), 0 ether);

        cold.doProxyLock(100 ether);
        assertEq(gov.balanceOf(address(cold)), 0 ether);
        assertEq(gov.balanceOf(address(chief)), 100 ether);

        tech.doProxyFree(100 ether);
        assertEq(gov.balanceOf(address(cold)), 100 ether);
        assertEq(gov.balanceOf(address(chief)), 0 ether);
    }

    function test_free_all() public {
        cold.approveGov(address(proxy));
        assertEq(gov.balanceOf(address(cold)), 100 ether);
        assertEq(gov.balanceOf(address(chief)), 0 ether);

        cold.doProxyLock(50 ether);
        cold.doTransfer(address(proxy), 25 ether);
        assertEq(gov.balanceOf(address(cold)), 25 ether);
        assertEq(gov.balanceOf(address(proxy)), 25 ether);
        assertEq(gov.balanceOf(address(chief)), 50 ether);

        cold.doProxyFreeAll();
        assertEq(gov.balanceOf(address(cold)), 100 ether);
        assertEq(gov.balanceOf(address(proxy)), 0 ether);
        assertEq(gov.balanceOf(address(chief)), 0 ether);
    }

    function testFail_no_proxy_approval() public {
        cold.doProxyLock(100 ether);
    }

    function testFail_random_free() public {
        cold.approveGov(address(proxy));
        cold.doProxyLock(100 ether);
        random.doProxyFree(100 ether);
    }

    function testFail_random_vote() public {
        cold.approveGov(address(proxy));
        cold.doProxyLock(100 ether);

        address[] memory yays = new address[](1);
        yays[0] = c1;
        random.doProxyVote(yays);
    }

    function testFail_vote_disabled_vote() public {
        cold.approveGov(address(proxy));
        cold.doProxyLock(100 ether);

        address[] memory yays = new address[](1);
        yays[0] = c1;
        tech.doProxyVote(yays);
    }
}
