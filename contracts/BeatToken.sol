pragma solidity ^0.4.18;


import "./../node_modules/zeppelin-solidity/contracts/token/CappedToken.sol";


contract BeatToken is CappedToken {

    string public constant name = "BEAT Token";
    string public constant symbol = "BEAT";
    uint8 public constant decimals = 18;

    function BeatToken(uint256 _cap) CappedToken(_cap) public {
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

}