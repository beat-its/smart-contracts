var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "...";

module.exports = {
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration!
    networks: {
        ropsten: {
            provider: function () {
                return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/...")
            },
            network_id: 3,
            gas: 4700000,
        },
        mainnet: {
            provider: function () {
                return new HDWalletProvider(mnemonic, "https://mainnet.infura.io/...")
            },
            network_id: 1,
            gas: 4700000,
            gasPrice: 41000000000,
        }
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 400
        }
    }
};
