// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import { ISuperToken, CustomSuperTokenBase } from "./interfaces/CustomSuperTokenBase.sol";
import { INativeSuperTokenCustom } from "./interfaces/INativeSuperToken.sol";
import { UUPSProxy } from "./upgradability/UUPSProxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INativeSuperTokenProxy {
  function initialize(string calldata name, string calldata symbol) external;

  function mint(uint256 amount) external;

  function burn(address account, uint256 amount) external;
}

contract NativeSuperTokenProxy is
  INativeSuperTokenProxy,
  CustomSuperTokenBase,
  UUPSProxy
{
  address public veNFT;

  function initialize(string calldata name, string calldata symbol)
    external
    override
  {
    ISuperToken(address(this)).initialize(
      IERC20(address(0)), // no underlying/wrapped token
      18, // shouldn't matter if there's no wrapped token
      name,
      symbol
    );

    veNFT = msg.sender;
  }

  function mint(uint256 amount) external override {
    require(msg.sender == veNFT);

    ISuperToken(address(this)).selfMint(msg.sender, amount, new bytes(0));
  }

  function burn(address account, uint256 amount) external override {
    require(msg.sender == veNFT);

    ISuperToken(address(this)).selfBurn(account, amount, new bytes(0));
  }
}
