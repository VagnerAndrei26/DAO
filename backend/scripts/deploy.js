const hre = require("hardhat");
const { CRYPTODEVS_NFT_CONTRACT_ADDRESS } = require("../constants");


async function main() {
  const SimpleNFTMarketplace = await ethers.getContractFactory(
    "SimpleNFTMarketplace"
  );
  const simpleNftMarketplace = await SimpleNFTMarketplace.deploy();
  await simpleNftMarketplace.deployed();

  console.log("SimpleNFTMarketplace deployed to: ", simpleNftMarketplace.address);

  // Now deploy the CryptoDevsDAO contract
  const SimpleDAO = await ethers.getContractFactory("SimpleDAO");
  const simpleDAO = await SimpleDAO.deploy(
    simpleNftMarketplace.address,
    CRYPTODEVS_NFT_CONTRACT_ADDRESS,
    {
      value: ethers.utils.parseEther("0.01"),
    }
  );
  await simpleDAO.deployed();

  console.log("SimpleDAO deployed to: ", simpleDAO.address);
}

// Async Sleep function
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
