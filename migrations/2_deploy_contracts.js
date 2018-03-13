const BeatOrgTokenMainSale = artifacts.require("BeatOrgTokenMainSale");
const BeatOrgToken = artifacts.require("BeatOrgToken");

const wallet = '0xd924669e34061B7b9D08b1cbB9c9A4Cdf00bc10c';

module.exports = function(deployer) {
    deployer.deploy(BeatOrgToken).then(function() {
        return deployer.deploy(BeatOrgTokenMainSale, wallet);
    });
};
