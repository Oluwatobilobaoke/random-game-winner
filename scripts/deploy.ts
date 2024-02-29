import { ethers } from "hardhat";

const initialOwner = "0x6694c714e3Be435Ad1e660C37Ea78351092b0075";
const LINK_TOKEN = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
const VRF_COORDINATOR = "0x8C7382F9D8f56b33781fE506E897a4F1e2d17255";
const KEY_HASH =
  "0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4";
const FEE = ethers.parseEther("0.0001");

async function main() {
  const erc20Contract = await ethers.deployContract("ERC20Token", [
    initialOwner,
    "WEB3CX",
    "W3B",
  ]);

  await erc20Contract.waitForDeployment();

  console.log(`ERC20 Token contract deployed to ${erc20Contract.target}`);

  // deploy the contract
  const randomWinnerGame = await ethers.deployContract("RandomWinnerGame", [
    initialOwner,
    VRF_COORDINATOR,
    LINK_TOKEN,
    KEY_HASH,
    FEE,
  ]);

  await randomWinnerGame.waitForDeployment();

  // print the address of the deployed contract
  console.log("Verify Contract Address:", randomWinnerGame.target);

  console.log("Sleeping.....");

  // Wait for etherscan to notice that the contract has been deployed
  await sleep(30000);


  function sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
