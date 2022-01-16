import { ethers, network, waffle } from "hardhat";
import { parseEther } from "@ethersproject/units";
import { AddressZero, MaxUint256, HashZero } from "@ethersproject/constants";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";

chai.use(solidity);
const { expect } = chai;
const { deployContract } = waffle;

// artifacts
import HelloWorldArtifact from "../artifacts/contracts/HelloWorld.sol/HelloWorld.json";

// types
import { HelloWorld } from "../typechain/HelloWorld";

describe("Hello World", () => {
  let helloWorld: HelloWorld;

  let deployer: SignerWithAddress;

  before(async () => {
    [deployer] = await ethers.getSigners();

    // deploy contracts
    helloWorld = (await deployContract(deployer, HelloWorldArtifact, [
      "world",
    ])) as HelloWorld;
  });

  it("should return correct string", async () => {
    const res = await helloWorld.hello();

    expect(res).to.be.equal("world");
  });
});
