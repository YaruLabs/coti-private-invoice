import hre from "hardhat";
import { setupAccounts } from "./utils/accounts";

async function main() {
  const [owner, recipient] = await setupAccounts();

  console.log("Deploying PrivateToken from:", owner.address);
  const TokenFactory = await hre.ethers.getContractFactory("PrivateToken");

  const token = await TokenFactory.connect(owner).deploy("Private Invoice Token", "PIT");
  await token.waitForDeployment();

  const tokenAddress = await token.getAddress();
  console.log("PrivateToken deployed at:", tokenAddress);

  const mintAmount = 1000;

  const tx1 = await token.connect(owner).mint(owner.address, mintAmount);
  await tx1.wait();
  console.log(`Minted ${mintAmount} tokens to owner: ${owner.address}`);

  const tx2 = await token.connect(owner).mint(recipient.address, mintAmount);
  await tx2.wait();
  console.log(`Minted ${mintAmount} tokens to recipient: ${recipient.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
