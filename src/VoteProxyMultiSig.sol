// VoteProxy - vote w/ a hot or cold wallet using a proxy identity
pragma solidity >=0.4.24;

import "ds-token/token.sol";
import "ds-chief/chief.sol";

contract VoteProxy {
    address public cold;
    mapping(address => uint256) public mgmt;
    mapping(address => uint256) public tech;

    DSToken public gov;
    DSToken public iou;
    DSChief public chief;

    uint256 public live = 0;

    constructor(DSChief _chief, address _cold, address[] _mgmt, address[] _tech) public {
        chief = _chief;
        cold = _cold;

        for (i = 0; i < _mgmt.length(); i++) {
            mgmt[_mgmt[i]] = 1;
        }
        for (i = 0; i < _tech.length(); i++) {
            tech[_tech[i]] = 1;
        }

        gov = chief.GOV();
        iou = chief.IOU();
        gov.approve(address(chief), uint256(-1));
        iou.approve(address(chief), uint256(-1));
    }

    modifier auth() {
        require(mgmt[msg.sender] == 1 || tech[msg.sender] == 1 || msg.sender == cold, "Sender must be a Cold or Hot Wallet");
        _;
    }

    modifier onlyManagement() {
        require(mgmt[msg.sender] == 1, "Sender must be from management");
        _;
    }

    modifier onlyTech() {
        require(tech[msg.sender] == 1, "Sender must be from tech");
        _;
    }

    modifier onlyCold() {
        require(msg.sender == cold, "Sender must be the Cold Wallet");
        _;
    }

    modifier isLive() {
        require(live == 1, "The contract must be unlocked by management");
        _;
    }

    function enable() public onlyManagement {
        live = 1;
    }

    function disable() public onlyManagement {
        live = 0;
    }

    function lock(uint256 wad) public auth {
        gov.pull(cold, wad);   // mkr from cold
        chief.lock(wad);       // mkr out, ious in
    }

    function free(uint256 wad) public auth {
        chief.free(wad);       // ious out, mkr in
        gov.push(cold, wad);   // mkr to cold
    }

    function freeAll() public auth {
        chief.free(chief.deposits(address(this)));
        gov.push(cold, gov.balanceOf(address(this)));
    }

    function vote(address[] memory yays) public onlyTech isLive returns (bytes32) {
        bytes32 votes = chief.vote(yays);
        live = 0;
        return votes;
    }

    function vote(bytes32 slate) public onlyTech isLive {
        chief.vote(slate);
        live = 0;
    }

    function nuke() public onlyCold {
        freeAll();
        selfdestruct(cold);
    }
}
