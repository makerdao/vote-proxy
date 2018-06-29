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

    function approveLink(address cold_) public returns (VoteProxy voteProxy) {
        address hot_ = msg.sender;
        requre(
            desiredLink[cold_] == hot_, 
            "Cold wallet must have initiated a link"
            );
        require(
            coldMap[hot_] == address(0) && hotMap[hot_] == address(0), 
            "Hot wallet cannot already have a Vote Proxy associated with it"
            );
        voteProxy = new VoteProxy(gov, chief, iou, cold_, hot_);
        hotMap[hot_] = voteProxy;
        coldMap[cold_] = voteProxy;
    }
    
    function initiateLink(address hot_) public {
        address cold_ = msg.sender;
        require(
            coldMap[cold_] == address(0) && hotMap[cold_] == address(0), 
            "Cold wallet cannot already have a Vote Proxy associated with it"
            );
        desiredLink[cold_] = hot_;
    }
}
