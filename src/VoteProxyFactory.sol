/// VoteProxyFactory.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// create and keep record of proxy identities
pragma solidity >=0.4.24;

import "./VoteProxy.sol";

contract VoteProxyFactory {
    ChiefLike public chief;
    mapping(address => VoteProxy) public hotMap;
    mapping(address => VoteProxy) public coldMap;
    mapping(address => address) public linkRequests;

    event LinkRequested(address indexed cold, address indexed hot);
    event LinkConfirmed(address indexed cold, address indexed hot, address indexed voteProxy);

    constructor(address chief_) public { chief = ChiefLike(chief_); }

    function hasProxy(address guy) public view returns (bool) {
        return (address(coldMap[guy]) != address(0x0) || address(hotMap[guy]) != address(0x0));
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

        voteProxy = new VoteProxy(address(chief), cold, msg.sender);
        hotMap[msg.sender] = voteProxy;
        coldMap[cold] = voteProxy;
        delete linkRequests[cold];
        emit LinkConfirmed(cold, msg.sender, address(voteProxy));
    }

    function breakLink() public {
        require(hasProxy(msg.sender), "No VoteProxy found for this sender");

        VoteProxy voteProxy = address(coldMap[msg.sender]) != address(0x0)
            ? coldMap[msg.sender] : hotMap[msg.sender];
        address cold = voteProxy.cold();
        address hot = voteProxy.hot();
        require(chief.deposits(address(voteProxy)) == 0, "VoteProxy still has funds attached to it");

        delete coldMap[cold];
        delete hotMap[hot];
    }

    function linkSelf() public returns (VoteProxy voteProxy) {
        initiateLink(msg.sender);
        return approveLink(msg.sender);
    }
}
