import hre from "hardhat"
import { setupAccounts } from "./utils/accounts"

async function main() {
    const [owner, otherAccount] = await setupAccounts()
    console.log("Owner address: ", owner.address)

    const PrivateStorageFactory = await hre.ethers.getContractFactory("PrivateInvoicing")
    console.log("Deploying PrivateStorage contract...")

    const privateStorage = await PrivateStorageFactory
        .connect(owner)
        .deploy()

    console.log("Waiting for deployment...")
    
    await privateStorage.waitForDeployment()

    console.log("Contract address: ", await privateStorage.getAddress())
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})