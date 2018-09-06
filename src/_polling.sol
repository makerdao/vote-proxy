// Polling – create expiring straw polls 

pragma solidity ^0.4.24;

import "ds-math/math.sol";
import "ds-token/token.sol";


contract Polling is DSMath {
    uint256 public npoll;
    DSToken public   gov; 

    mapping (uint256 => Poll) public polls;    
    mapping (address => Checkpoint[]) public deposits;

    // idea credit Aragon Voting app
    enum VoterStatus { Absent, Yea, Nay }
    
    struct Checkpoint {
        uint128 fromBlock;
        uint128 value;
    }

    struct Multihash {
        bytes32 digest;
        uint8 hashFunction;
        uint8 size;
    }

    struct Poll {
        uint32 frozenAt;
        uint48 start;
        uint48 end;            
        uint256 yea;		 
        uint256 nay; 
        address[] voters;
        Multihash ipfsHash;
        mapping(address => VoterStatus) votes; 
    }

    event PollCreated(address src, uint48 start, uint48 end, uint32 frozenAt, uint256 id);
    event Voted(address src, uint256 id, bool yea, uint256 weight, bytes logData);
    event UnSaid(address src, uint256 id, uint256 weight);

    constructor(DSToken _gov) public { gov = _gov; }

    function era() public view returns (uint48) { return uint48(now); }
    function age() public view returns (uint32) { return uint32(block.number); }

    function lock(uint256 wad) public {
        gov.pull(msg.sender, wad);
        updateDeposits(deposits[msg.sender], add(getDeposits(msg.sender), wad));
    }

    function free(uint256 wad) public {
        gov.push(msg.sender, wad);
        updateDeposits(deposits[msg.sender], sub(getDeposits(msg.sender), wad));
    }

    function pollExists(uint256 _id) public view returns (bool) {
        return _id < npoll;
    }

    function pollActive(uint256 _id) public view returns (bool) {
        return (era() >= polls[_id].start && era() < polls[_id].end);
    }

    function createPoll(
        uint48 _ttl,
        bytes32 _digest, 
        uint8 _hashFunction, 
        uint8 _size
    ) public returns (uint256) {
        require(_ttl > 0);
        uint32 _frozenAt = age() - 1;
        uint48 _start = era();
        uint48 _end = uint48(add(_start, mul(_ttl, 1 days)));
        Poll storage poll = polls[npoll];
        poll.ipfsHash = Multihash(_digest, _hashFunction, _size);
        poll.frozenAt = _frozenAt;
        poll.start = _start;
        poll.end = _end;
        emit PollCreated(msg.sender, _start, _end, _frozenAt, npoll);
        return npoll++;
    }
    
    function vote(uint256 _id, bool _yea, bytes _logData) public {
        require(pollExists(_id) && pollActive(_id), "id must be of a valid and active poll");

        Poll storage poll = polls[_id];
        uint256 weight = depositsAt(msg.sender, poll.frozenAt);

        require(weight > 0, "must have voting rights in this poll");
        subWeight(weight, msg.sender, poll);
        addWeight(weight, msg.sender, poll, _yea);
        emit Voted(msg.sender, _id, _yea, weight, _logData);
    }
             
    function unSay(uint256 _id) public {
        require(pollExists(_id) && pollActive(_id), "id must be of a valid and active poll");

        Poll storage poll = polls[_id];
        uint256 weight = depositsAt(msg.sender, poll.frozenAt);

        require(weight > 0, "must have voting rights in this poll");
        subWeight(weight, msg.sender, poll);
        poll.votes[msg.sender] = VoterStatus.Absent;
        emit UnSaid(msg.sender, _id, weight);
    }

    function getDeposits(address _guy) public view returns (uint256) {
        return depositsAt(_guy, age());
    }

    // logic adapted from the minime token https://github.com/Giveth/minime –> credit Jordi Baylina
    function depositsAt(address _guy, uint256 _block) public view returns (uint) {
        Checkpoint[] storage checkpoints = deposits[_guy];
        if (checkpoints.length == 0) return 0;
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock)
            return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
        uint256 min = 0;
        uint256 max = checkpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

    // Internal -----------------------------------------------------

    function updateDeposits(Checkpoint[] storage checkpoints, uint256 _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < age())) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = age();
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }

    function subWeight(uint256 _weight, address _guy, Poll storage poll) internal {
        if (poll.votes[_guy] != VoterStatus.Absent) {
            if (poll.votes[_guy] == VoterStatus.Yea) poll.yea = sub(poll.yea, _weight);
            else poll.nay = sub(poll.nay, _weight);
        }
    }

    function addWeight(uint256 _weight, address _guy, Poll storage poll, bool _yea) internal {
        if (_yea) poll.yea = add(poll.yea, _weight);
        else poll.nay = add(poll.nay, _weight);
        poll.votes[_guy] = _yea ? VoterStatus.Yea : VoterStatus.Nay;
        poll.voters.push(_guy);
    }

    // Getters ------------------------------------------------------

    function getPoll(uint256 _id) public view returns (uint48, uint48, uint32, uint256, uint256) {
        Poll storage poll = polls[_id];
        return (poll.start, poll.end, poll.frozenAt, poll.yea, poll.nay);
    }
    
    function getVoterStatus(uint256 _id, address _guy) public view returns (uint256, uint256) {
        Poll storage poll = polls[_id];
        return (uint256(poll.votes[_guy]), depositsAt(_guy, poll.frozenAt));
        // status codes -> 0 := not voting, 1 := voting yea, 2 := voting nay
    }

    function getMultiHash(uint256 _id) public view returns (bytes32, uint256, uint256) {
        Multihash storage multihash = polls[_id].ipfsHash;
        return (multihash.digest, uint256(multihash.hashFunction), uint256(multihash.size));
    }
}