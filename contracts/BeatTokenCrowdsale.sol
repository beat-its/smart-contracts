pragma solidity ^0.4.18;

import "./BeatToken.sol";

contract BeatTokenCrowdsale is Ownable {

    enum Stages {
        Deployed,
        PreIco,
        IcoPhase1,
        IcoPhase2,
        IcoPhase3,
        IcoEnded,
        Finalized
    }
    Stages public stage;

    using SafeMath for uint256;

    BeatToken public token;

    uint256 public contractStartTime;
    uint256 public preIcoEndTime;
    uint256 public icoPhase1EndTime;
    uint256 public icoPhase2EndTime;
    uint256 public icoPhase3EndTime;
    uint256 public contractEndTime;

    address public ethTeamWallet;
    address public beatTeamWallet;

    uint256 public ethWeiRaised;
    mapping(address => uint256) public balanceOf;

    uint public constant PRE_ICO_PERIOD = 28 days;
    uint public constant ICO_PHASE1_PERIOD = 28 days;
    uint public constant ICO_PHASE2_PERIOD = 28 days;
    uint public constant ICO_PHASE3_PERIOD = 28 days;

    uint256 public constant PRE_ICO_BONUS_PERCENTAGE = 100;
    uint256 public constant ICO_PHASE1_BONUS_PERCENTAGE = 75;
    uint256 public constant ICO_PHASE2_BONUS_PERCENTAGE = 50;
    uint256 public constant ICO_PHASE3_BONUS_PERCENTAGE = 25;

    // 5.0 bn (2.5 bn regular + 2.5 bn bonus)
    uint256 public constant PRE_ICO_AMOUNT = 5000 * (10 ** 6) * (10 ** 18);
    // 7.0 bn (4.0 bn regular + 3.0 bn bonus)
    uint256 public constant ICO_PHASE1_AMOUNT = 7000 * (10 ** 6) * (10 ** 18);
    // 10.5 bn (7.0 bn regular + 3.5 bn bonus)
    uint256 public constant ICO_PHASE2_AMOUNT = 10500 * (10 ** 6) * (10 ** 18);
    // 11.875 bn (9.5 bn regular + 2.375 bn bonus)
    uint256 public constant ICO_PHASE3_AMOUNT = 11875 * (10 ** 6) * (10 ** 18);

    uint256 public constant PRE_ICO_LIMIT = PRE_ICO_AMOUNT;
    uint256 public constant ICO_PHASE1_LIMIT = PRE_ICO_LIMIT + ICO_PHASE1_AMOUNT;
    uint256 public constant ICO_PHASE2_LIMIT = ICO_PHASE1_LIMIT + ICO_PHASE2_AMOUNT;
    uint256 public constant ICO_PHASE3_LIMIT = ICO_PHASE2_LIMIT + ICO_PHASE3_AMOUNT;

    // 230 bn
    uint256 public constant HARD_CAP = 230 * (10 ** 9) * (10 ** 18);

    uint256 public ethPriceInEuroCent;

    event BeatTokenPurchased(address indexed purchaser, address indexed beneficiary, uint256 ethWeiAmount, uint256 beatWeiAmount);
    event BeatTokenEthPriceChanged(uint256 newPrice);
    event BeatTokenPreIcoStarted();
    event BeatTokenIcoPhase1Started();
    event BeatTokenIcoPhase2Started();
    event BeatTokenIcoPhase3Started();
    event BeatTokenIcoFinalized();

    function BeatTokenCrowdsale(address _ethTeamWallet, address _beatTeamWallet) public {
        require(_ethTeamWallet != address(0));
        require(_beatTeamWallet != address(0));

        token = new BeatToken(HARD_CAP);
        stage = Stages.Deployed;
        ethTeamWallet = _ethTeamWallet;
        beatTeamWallet = _beatTeamWallet;
        ethPriceInEuroCent = 0;

        contractStartTime = 0;
        preIcoEndTime = 0;
        icoPhase1EndTime = 0;
        icoPhase2EndTime = 0;
        icoPhase3EndTime = 0;
        contractEndTime = 0;
    }

    function setEtherPriceInEuroCent(uint256 _ethPriceInEuroCent) onlyOwner public {
        ethPriceInEuroCent = _ethPriceInEuroCent;
        BeatTokenEthPriceChanged(_ethPriceInEuroCent);
    }

    function start() onlyOwner public {
        require(stage == Stages.Deployed);
        require(ethPriceInEuroCent > 0);

        contractStartTime = now;
        BeatTokenPreIcoStarted();

        stage = Stages.PreIco;
    }

    function finalize() onlyOwner public {
        require(stage != Stages.Deployed);
        require(stage != Stages.Finalized);

        if (preIcoEndTime == 0) {
            preIcoEndTime = now;
        }
        if (icoPhase1EndTime == 0) {
            icoPhase1EndTime = now;
        }
        if (icoPhase2EndTime == 0) {
            icoPhase2EndTime = now;
        }
        if (icoPhase3EndTime == 0) {
            icoPhase3EndTime = now;
        }
        if (contractEndTime == 0) {
            contractEndTime = now;
        }

        uint256 unsoldTokens = HARD_CAP - token.getTotalSupply();
        token.mint(beatTeamWallet, unsoldTokens);

        BeatTokenIcoFinalized();

        stage = Stages.Finalized;
    }

    function() payable public {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) payable public {
        require(isWithinValidIcoPhase());
        require(ethPriceInEuroCent > 0);
        require(beneficiary != address(0));
        require(msg.value != 0);

        uint256 ethWeiAmount = msg.value;
        // calculate BEAT wei amount to be created
        uint256 beatWeiAmount = calculateBeatWeiAmount(ethWeiAmount);
        require(isWithinTokenAllocLimit(beatWeiAmount));

        determineCurrentStage(beatWeiAmount);

        balanceOf[beneficiary] += beatWeiAmount;
        ethWeiRaised += ethWeiAmount;

        token.mint(beneficiary, beatWeiAmount);
        BeatTokenPurchased(msg.sender, beneficiary, ethWeiAmount, beatWeiAmount);

        ethTeamWallet.transfer(ethWeiAmount);
    }

    function isWithinValidIcoPhase() internal view returns (bool) {
        return (stage == Stages.PreIco || stage == Stages.IcoPhase1 || stage == Stages.IcoPhase2 || stage == Stages.IcoPhase3);
    }

    function calculateBeatWeiAmount(uint256 ethWeiAmount) internal view returns (uint256) {
        uint256 beatWeiAmount = ethWeiAmount.mul(ethPriceInEuroCent);
        uint256 bonusPercentage = 0;

        if (stage == Stages.PreIco) {
            bonusPercentage = PRE_ICO_BONUS_PERCENTAGE;
        } else if (stage == Stages.IcoPhase1) {
            bonusPercentage = ICO_PHASE1_BONUS_PERCENTAGE;
        } else if (stage == Stages.IcoPhase2) {
            bonusPercentage = ICO_PHASE2_BONUS_PERCENTAGE;
        } else if (stage == Stages.IcoPhase3) {
            bonusPercentage = ICO_PHASE3_BONUS_PERCENTAGE;
        }

        // implement poor man's rounding by adding 50 because all integer divisions rounds DOWN to nearest integer
        return beatWeiAmount.mul(100 + bonusPercentage).add(50).div(100);
    }

    function isWithinTokenAllocLimit(uint256 beatWeiAmount) internal view returns (bool) {
        return token.getTotalSupply().add(beatWeiAmount) <= ICO_PHASE3_LIMIT;
    }

    function determineCurrentStage(uint256 beatWeiAmount) internal {
        uint256 newTokenTotalSupply = token.getTotalSupply().add(beatWeiAmount);

        if (stage == Stages.PreIco && (newTokenTotalSupply > PRE_ICO_LIMIT || now >= contractStartTime + PRE_ICO_PERIOD)) {
            preIcoEndTime = now;
            stage = Stages.IcoPhase1;
            BeatTokenIcoPhase1Started();
        } else if (stage == Stages.IcoPhase1 && (newTokenTotalSupply > ICO_PHASE1_LIMIT || now >= preIcoEndTime + ICO_PHASE1_PERIOD)) {
            icoPhase1EndTime = now;
            stage = Stages.IcoPhase2;
            BeatTokenIcoPhase2Started();
        } else if (stage == Stages.IcoPhase2 && (newTokenTotalSupply > ICO_PHASE2_LIMIT || now >= icoPhase1EndTime + ICO_PHASE2_PERIOD)) {
            icoPhase2EndTime = now;
            stage = Stages.IcoPhase3;
            BeatTokenIcoPhase3Started();
        } else if (stage == Stages.IcoPhase3 && (newTokenTotalSupply == ICO_PHASE3_LIMIT || now >= icoPhase2EndTime + ICO_PHASE3_PERIOD)) {
            icoPhase3EndTime = now;
            stage = Stages.IcoEnded;
        }
    }

}
