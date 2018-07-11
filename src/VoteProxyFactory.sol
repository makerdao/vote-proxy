pragma solidity ^0.4.21;

import "./VoteProxy.sol";

contract VoteProxyFactory {
    DSChief public chief;
    DSToken public gov;
    DSToken public iou;
    mapping(address=>VoteProxy) public hotMap;
    mapping(address=>VoteProxy) public coldMap;
    mapping(address=>address) public desiredLink;
    
    constructor(DSChief chief_) public {
        chief = chief_;
        gov = chief.GOV();
        iou = chief.IOU();
    }

    function approveLink(address cold) public returns (VoteProxy voteProxy) {
        address hot = msg.sender;

        bool mutualInterest = desiredLink[cold] == hot;
        requre(mutualInterest, "Cold wallet must have initiated a link");

        bool hotHasProxy = coldMap[hot] != address(0) || hotMap[hot] != address(0);
        require(!hotHasProxy, "Hot wallet cannot already have a Vote Proxy associated with it");

        voteProxy = new VoteProxy(gov, chief, iou, cold, hot);
        hotMap[hot] = voteProxy;
        coldMap[cold] = voteProxy;
    }
    
    function initiateLink(address hot) public {
        address cold = msg.sender;

        bool coldHasProxy = coldMap[cold] != address(0) || hotMap[cold] != address(0);
        require(!coldHasProxy, "Cold wallet cannot already have a Vote Proxy associated with it");

        bool hotHasProxy = coldMap[hot] != address(0) || hotMap[hot] != address(0);
        require(!hotHasProxy, "Hot wallet cannot already have a Vote Proxy associated with it");

        desiredLink[cold] = hot;
    }
}
