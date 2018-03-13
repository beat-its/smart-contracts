pragma solidity ^0.4.18;

import "./../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract BeatOrgTokenMainSale is Ownable {
    using SafeMath for uint256;

    address public wallet;

    uint256 public endTime;
    bool public finalized;

    uint256 public weiRaised;
    mapping(address => uint256) public purchases;

    event Purchase(address indexed purchaser, address indexed beneficiary, uint256 weiAmount);

    function BeatOrgTokenMainSale(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;

        // 2018-05-15T23:59:59+02:00
        endTime = 1526421599;
        finalized = false;
    }

    function() payable public {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) payable public {
        require(beneficiary != address(0));
        require(msg.value != 0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        purchases[beneficiary] += weiAmount;
        weiRaised += weiAmount;

        Purchase(msg.sender, beneficiary, weiAmount);

        wallet.transfer(weiAmount);
    }

    function finalize() onlyOwner public {
        endTime = now;
        finalized = true;
    }

    function validPurchase() internal view returns (bool) {
        return (now <= endTime) && (finalized == false);
    }

}
