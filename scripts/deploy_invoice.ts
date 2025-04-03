import hre from "hardhat";
import { setupAccounts } from "./utils/accounts";

async function main() {
  const [owner] = await setupAccounts();
  console.log("Owner address:", owner.address);

  const paymentTokenAddress = process.env.PAYMENT_TOKEN_ADDRESS;
  if (!paymentTokenAddress) {
    throw new Error("Please set PAYMENT_TOKEN_ADDRESS in your .env file");
  }

  const InvoiceFactory = await hre.ethers.getContractFactory("PrivateInvoicing");

  console.log("Deploying PrivateInvoicing contract...");
  const invoiceContract = await InvoiceFactory.connect(owner).deploy();
  await invoiceContract.waitForDeployment();

  const contractAddress = await invoiceContract.getAddress();
  console.log("PrivateInvoicing deployed at:", contractAddress);

  console.log("Setting payment token address...");
  const tx = await invoiceContract.connect(owner).setPaymentToken(paymentTokenAddress);
  await tx.wait();

  console.log("Payment token set to:", paymentTokenAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});