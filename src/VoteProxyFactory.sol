pragma solidity ^0.4.21;

import "./VoteProxy.sol";

contract VoteProxyFactory {
    DSChief public chief;
    DSToken public gov;
    DSToken public iou;
    mapping(address=>VoteProxy) public hotMap;
    mapping(address=>VoteProxy) public coldMap;
    mapping(address=>address) public linkRequests;

    event LinkRequested(address indexed cold, address indexed hot);
    event LinkConfirmed(address indexed cold, address indexed hot, address indexed voteProxy);
    
    constructor(DSChief chief_) public {
        chief = chief_;
        gov = chief.GOV();
        iou = chief.IOU();
    }

    function hasProxy(address guy) public view returns (bool) {
        return coldMap[guy] != address(0) || hotMap[guy] != address(0);
    }

    function initiateLink(address hot) public {
        address cold = msg.sender;

        require(!hasProxy(cold), "Cold wallet cannot already be linked to a Vote Proxy");
        require(!hasProxy(hot), "Hot wallet cannot already be linked to a Vote Proxy");
        require(cold != hot, "Hot wallet cannot be the same as the cold wallet"); // should we allow this?

        linkRequests[cold] = hot;
        emit LinkRequested(cold, hot);
    }

    function approveLink(address cold) public returns (VoteProxy voteProxy) {
        address hot = msg.sender;

        bool mutualInterest = linkRequests[cold] == hot;
        require(mutualInterest, "Cold wallet must initiate a link first");
        require(!hasProxy(hot), "Hot wallet cannot already be linked to a Vote Proxy");

        voteProxy = new VoteProxy(gov, chief, iou, cold, hot);
        hotMap[hot] = voteProxy;
        coldMap[cold] = voteProxy;
        delete linkRequests[cold];
        emit LinkConfirmed(cold, hot, voteProxy);
    }
}
