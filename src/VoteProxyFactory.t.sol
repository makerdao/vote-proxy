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

    function doTransfer(DSToken token, address to, uint amount) public {
        token.transfer(to, amount);
    }
}


contract VoteProxyFactoryTest is DSTest {
    uint256 constant electionSize = 3;

    VoteProxyFactory voteProxyFactory;
    DSToken gov;
    DSToken iou;
    DSChief chief;
    Polling polling;

    VoteUser cold;
    VoteUser hot;

    function setUp() public {
        gov = new DSToken("GOV");

        DSChiefFab fab = new DSChiefFab();
        chief = fab.newChief(gov, electionSize);
        polling = new Polling(chief.IOU());
        voteProxyFactory = new VoteProxyFactory(chief, polling);
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

    function testFail_BreakLink() public {
        cold.doInitiateLink(hot);
        VoteProxy voteProxy = hot.doApproveLink(cold);
        chief.GOV().mint(cold, 1);
        cold.doTransfer(chief.GOV(), voteProxy, 1);
        cold.doBreakLink();
    }

    function test_linkSelf() public { // misnomer, transfer uneccessary
        assertEq(voteProxyFactory.coldMap(cold), address(0));
        VoteProxy voteProxy = cold.doLinkSelf();
        assertEq(voteProxyFactory.coldMap(cold), voteProxy);
        assertEq(voteProxyFactory.coldMap(cold).cold(), cold);
        assertEq(voteProxyFactory.hotMap(cold).hot(), cold);
    }
}