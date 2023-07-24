import { Wallet, utils } from "zksync-web3";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import dotenv from "dotenv";
dotenv.config();

const PRIVATE_KEY =
  process.env.WALLET_PRIVATE_KEY ||
  "c2d5473c1a7263d4c36f2a426845e62c2869aea11143a0463b8648010d954ad6";
if (!PRIVATE_KEY)
  throw "⛔️ Private key not detected! Add it to the .env file!";

export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running deploy script for the contract`);

  const wallet = new Wallet(PRIVATE_KEY);

  // Create deployer object and load the artifact of the contract you want to deploy.
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("YieldFarm");

  const YieldFarmContract = await deployer.deploy(artifact, [
    "0xBd229574b4cF46600e530ca7Eab6c9AF9e83671e", // soba
    "0x4999de98ff7Fe48137304979d957CB1e5CdA28e3", // dev address
    0,
    0,
  ]);

  //const ERC20Contract = await deployer.deploy(artifact, ["SOBAJA", "SBJ"]);

  // Show the contract info.
  const contractAddress = YieldFarmContract.address;
  console.log(`${artifact.contractName} was deployed to ${contractAddress}`);
}
