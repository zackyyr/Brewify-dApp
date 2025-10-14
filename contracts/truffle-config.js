require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const { PRIVATE_KEY_GANACHE, PRIVATE_KEY_SEPOLIA, INFURA_API_KEY, ALCHEMY_API_KEY } = process.env;


module.exports = {
    networks: {
        // Ganache Lokal
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*", // 1337/5777
        },
        // Sepolia Testnet
        sepolia: {
            provider: () => new HDWalletProvider(
                [PRIVATE_KEY_SEPOLIA],
                INFURA_API_KEY
                    ? `https://sepolia.infura.io/v3/${INFURA_API_KEY}`
                    : `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`
            ),
            network_id: 11155111,
            confirmations: 2,
            timeoutBlocks: 200,
            skipDryRun: true,
        },
    },
    compilers: {
        solc: {
            version: "0.8.20",
            settings: {
                evmVersion: "paris" // Menargetkan EVM yang lebih kompatibel
            }
        }
    },
};