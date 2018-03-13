pragma solidity ^0.4.18;

import "./../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol";


contract BeatOrgToken is MintableToken {
    using SafeMath for uint256;

    string public constant name = "BEAT";
    string public constant symbol = "BEAT";
    uint8 public constant decimals = 18;

    // 5 bn
    uint256 public constant HARD_CAP = 5 * (10 ** 9) * (10 ** 18);

    event Burn(address indexed burner, uint256 value);

    function batchMint(address[] _to, uint256[] _amount) external canMint returns (bool) {
        require(_to.length == _amount.length);
        for (uint i = 0; i < _to.length; i++) {
            require(_to[i] != address(0));
            require(mint(_to[i], _amount[i]));
        }
        return true;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(_amount > 0);
        require(totalSupply.add(_amount) <= HARD_CAP);
        return super.mint(_to, _amount);
    }

    function burn(uint256 _value) onlyOwner public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

}