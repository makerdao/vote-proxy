// VoteProxyFactory - create and keep record of proxy identities

pragma solidity ^0.4.24;

import "./VoteProxy.sol";


contract VoteProxyFactory {
    DSChief public chief;
    Polling public polling;
    mapping(address => VoteProxy) public hotMap;
    mapping(address => VoteProxy) public coldMap;
    mapping(address => address) public linkRequests;

    event LinkRequested(address indexed cold, address indexed hot);
    event LinkConfirmed(address indexed cold, address indexed hot, address indexed voteProxy);
    
    constructor(DSChief chief_, Polling polling_) public {
        chief = chief_;
        polling = polling_;
    }

    function hasProxy(address guy) public view returns (bool) {
        return (coldMap[guy] != address(0) || hotMap[guy] != address(0));
    }

    function initiateLink(address hot) public {
        require(!hasProxy(msg.sender), "Cold wallet is already linked to another Vote Proxy");
        require(!hasProxy(hot), "Hot wallet is already linked to another Vote Proxy");

        linkRequests[msg.sender] = hot;
        emit LinkRequested(msg.sender, hot);
    }

    function approveLink(address cold) public returns (VoteProxy voteProxy) {
        require(linkRequests[cold] == msg.sender, "Cold wallet must initiate a link first");
        require(!hasProxy(msg.sender), "Hot wallet is already linked to another Vote Proxy");

        voteProxy = new VoteProxy(chief, polling, cold, msg.sender);
        hotMap[msg.sender] = voteProxy;
        coldMap[cold] = voteProxy;
        delete linkRequests[cold];
        emit LinkConfirmed(cold, msg.sender, voteProxy);
    }

    function breakLink() public {
        require(hasProxy(msg.sender), "No VoteProxy found for this sender");

        VoteProxy voteProxy;
        address cold;
        address hot;
        if (coldMap[msg.sender] != address(0)) {
            voteProxy = coldMap[msg.sender];
            cold = msg.sender;
            hot = coldMap[msg.sender].hot();
        } else {
            voteProxy = hotMap[msg.sender];
            cold = hotMap[msg.sender].cold();
            hot = msg.sender;
        }

        require(
            chief.GOV().balanceOf(voteProxy) == 0 && chief.IOU().balanceOf(voteProxy) == 0, 
            "VoteProxy has still funds attached to it"
        );

        delete coldMap[cold];
        delete hotMap[hot];
    }

    function linkSelf() public returns (VoteProxy voteProxy) {
        require(!hasProxy(msg.sender));
        initiateLink(msg.sender);
        return approveLink(msg.sender);
    }
}
