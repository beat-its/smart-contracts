const BeatTokenCrowdsale = artifacts.require("BeatTokenCrowdsale");

const ethTeamWallet = '0xd924669e34061B7b9D08b1cbB9c9A4Cdf00bc10c';
const beatTeamWallet = '0xaD1e5d8fc67a95f5270ac9Eac50A433Ba46A724C';

module.exports = function(deployer) {
    deployer.deploy(BeatTokenCrowdsale, ethTeamWallet, beatTeamWallet);
};