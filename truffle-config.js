require('babel-register');
require('babel-polyfill');

var HDWalletProvider =require("truffle-hdwallet-provider")
var mnemonic = "distance tonight tray payment shoe tone assist trade gun valley naive wisdom"

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: function() { 
       return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/e93f4d28b4154d24a517ea675b19b8b9");
      },
      network_id: 4,
      gas: 4500000,
      gasPrice: 10000000000,
    },
    bscTestnet: {
      provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },

  },
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',
  compilers: {
    solc: {
      version: "0.6.8",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}
