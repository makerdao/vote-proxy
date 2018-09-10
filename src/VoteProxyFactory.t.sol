pragma solidity ^0.4.24;

import "ds-test/test.sol";
import "./VoteProxyFactory.sol";


contract VoteUser {
    DSChief chief;
    VoteProxyFactory voteProxyFactory;

    constructor(VoteProxyFactory voteProxyFactory_) public {
        voteProxyFactory = voteProxyFactory_;
    }

    function doInitiateLink(address hot) public {
        voteProxyFactory.initiateLink(hot);
    }

    function doApproveLink(address cold) public returns (VoteProxy) {
        return voteProxyFactory.approveLink(cold);
    }

    function doLinkSelf() public returns (VoteProxy) {
        return voteProxyFactory.linkSelf();
    }

    function doBreakLink() public {
        voteProxyFactory.breakLink();
    }

    function tryBreakLink() public returns (bool) {
        bytes4 sig = bytes4(keccak256("breakLink()"));
        return address(voteProxyFactory).call(sig);
    }

    function proxyApprove(address _proxy, DSToken _token) public {
        _token.approve(_proxy);
    }

    function proxyLock(VoteProxy _proxy, uint amount) public {
        _proxy.lock(amount);
    }

    function proxyFree(VoteProxy _proxy, uint amount) public {
        _proxy.free(amount);
    }
}


contract VoteProxyFactoryTest is DSTest {
    uint256 constant electionSize = 3;

    VoteProxyFactory voteProxyFactory;
    DSToken gov;
    DSToken iou;
    DSChief chief;

    VoteUser cold;
    VoteUser hot;

    function setUp() public {
        gov = new DSToken("GOV");

        DSChiefFab fab = new DSChiefFab();
        chief = fab.newChief(gov, electionSize);
        voteProxyFactory = new VoteProxyFactory(chief);
        cold = new VoteUser(voteProxyFactory);
        hot  = new VoteUser(voteProxyFactory);
    }

    function test_initiateLink() public {
        assertEq(voteProxyFactory.linkRequests(cold), address(0));
        cold.doInitiateLink(hot);
        assertEq(voteProxyFactory.linkRequests(cold), hot);
    }

    function test_approveLink() public {
        assertEq(voteProxyFactory.coldMap(cold), address(0));
        assertEq(voteProxyFactory.hotMap(hot), address(0));
        cold.doInitiateLink(hot);
        hot.doApproveLink(cold);
        assertEq(voteProxyFactory.coldMap(cold), voteProxyFactory.hotMap(hot));
        assertEq(voteProxyFactory.coldMap(cold).cold(), cold);
        assertEq(voteProxyFactory.hotMap(hot).hot(), hot);
    }

    function test_coldBreakLink() public {
        cold.doInitiateLink(hot);
        hot.doApproveLink(cold);
        assertTrue(voteProxyFactory.coldMap(cold) != address(0));
        assertTrue(voteProxyFactory.hotMap(hot) != address(0));
        cold.doBreakLink();
        assertEq(voteProxyFactory.coldMap(cold), address(0));
        assertEq(voteProxyFactory.hotMap(hot), address(0));
    }

    function test_hotBreakLink() public {
        cold.doInitiateLink(hot);
        hot.doApproveLink(cold);
        assertTrue(voteProxyFactory.coldMap(cold) != address(0));
        assertTrue(voteProxyFactory.hotMap(hot) != address(0));
        hot.doBreakLink();
        assertEq(voteProxyFactory.coldMap(cold), address(0));
        assertEq(voteProxyFactory.hotMap(hot), address(0));
    }

    function test_tryBreakLink() public {
        cold.doInitiateLink(hot);
        VoteProxy voteProxy = hot.doApproveLink(cold);
        chief.GOV().mint(cold, 1);
        cold.proxyApprove(voteProxy, chief.GOV());
        cold.proxyLock(voteProxy, 1);
        assertTrue(!cold.tryBreakLink());

        cold.proxyFree(voteProxy, 1);
        assertTrue(cold.tryBreakLink());
    }

    function test_linkSelf() public { // misnomer, transfer uneccessary
        assertEq(voteProxyFactory.coldMap(cold), address(0));
        VoteProxy voteProxy = cold.doLinkSelf();
        assertEq(voteProxyFactory.coldMap(cold), voteProxy);
        assertEq(voteProxyFactory.coldMap(cold).cold(), cold);
        assertEq(voteProxyFactory.hotMap(cold).hot(), cold);
    }

    function testFail_linkSelf() public { // misnomer, transfer uneccessary
        assertEq(voteProxyFactory.coldMap(cold), address(0));
        cold.doInitiateLink(hot);
        hot.doApproveLink(cold);
        assertEq(voteProxyFactory.coldMap(cold), hot);
        cold.doLinkSelf();
    }
}
