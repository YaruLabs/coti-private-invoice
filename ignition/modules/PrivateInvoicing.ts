// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const PrivateInvoicingModule = buildModule("PrivateInvoicingModule", (m) => {
  const privateInvoicing = m.contract("PrivateInvoicing");

  return { privateInvoicing };
});

export default PrivateInvoicingModule;
