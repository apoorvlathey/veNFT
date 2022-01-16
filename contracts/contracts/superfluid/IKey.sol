// SPDX-License-Identifier: AGPLv3
///@author @apoorvlathey

pragma solidity 0.8.7;
import { INativeSuperToken } from "./interfaces/INativeSuperToken.sol";
import { INativeSuperTokenProxy } from "./NativeSuperTokenProxy.sol";

interface IKey is INativeSuperToken, INativeSuperTokenProxy {}
