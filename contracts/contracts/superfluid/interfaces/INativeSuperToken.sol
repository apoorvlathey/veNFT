// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.0;

import { ISuperToken } from "./ISuperToken.sol";

/**
 * @dev Native SuperToken custom token functions
 *
 * @author Superfluid
 */
interface INativeSuperTokenCustom {
  function initialize(
    string calldata name,
    string calldata symbol,
    uint256 initialSupply
  ) external;
}

/**
 * @dev Native SuperToken full interface
 *
 * @author Superfluid
 */
interface INativeSuperToken is INativeSuperTokenCustom, ISuperToken {
  function initialize(
    string calldata name,
    string calldata symbol,
    uint256 initialSupply
  ) external override;
}
