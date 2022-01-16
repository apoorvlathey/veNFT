// SPDX-License-Identifier: AGPLv3
///@author @apoorvlathey

pragma solidity 0.8.7;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { NativeSuperTokenProxy } from "./superfluid/NativeSuperTokenProxy.sol";
import { IKey } from "./superfluid/IKey.sol";
import { ISuperTokenFactory } from "./superfluid/interfaces/ISuperTokenFactory.sol";
import { ISuperfluid } from "./superfluid/interfaces/ISuperfluid.sol";
import { IConstantFlowAgreementV1 } from "./superfluid/interfaces/IConstantFlowAgreementV1.sol";

contract veNFT is ERC721, Ownable {
  string baseURI;
  IKey public KEY;
  uint256 constant KEYS_PER_NFT_PER_SECOND = 1157407407407407; // ~ 100 KEYS per NFT per DAY
  ISuperfluid private _host;
  IConstantFlowAgreementV1 private _cfa; // constant flow agreement class address

  uint256 public maxSupply;
  uint256 public lastId;

  uint256 public maxPrice;
  uint256 public minLockDuration;

  uint256 public minPrice;
  uint256 public maxLockDuration;

  uint256 public mintStartTime;

  // tokenId => lockDuration
  mapping(uint256 => uint256) public lockDuration;
  mapping(uint256 => uint256) public mintedAt;
  mapping(uint256 => bool) public isUnlocked;

  constructor(
    string memory _name,
    string memory _symbol,
    ISuperTokenFactory _superTokenFactory,
    ISuperfluid host,
    IConstantFlowAgreementV1 cfa,
    string memory _newBaseURI,
    uint256 _maxSupply,
    uint256 _maxPrice,
    uint256 _minLockDuration,
    uint256 _minPrice,
    uint256 _maxLockDuration,
    uint256 _mintStartTime
  ) ERC721(_name, _symbol) {
    baseURI = _newBaseURI;
    maxSupply = _maxSupply;

    maxPrice = _maxPrice;
    minLockDuration = _minLockDuration;
    minPrice = _minPrice;
    maxLockDuration = _maxLockDuration;

    mintStartTime = _mintStartTime;

    _host = host;
    _cfa = cfa;

    KEY = IKey(address(new NativeSuperTokenProxy()));
    // Set the proxy to use the Super Token logic managed by Superfluid Protocol Governance
    _superTokenFactory.initializeCustomSuperToken(address(KEY));
    // Set up the token
    KEY.initialize("KEY", "KEY");
  }

  function mint(uint256 _lockDuration) external payable {
    require(block.timestamp >= mintStartTime, "!mintStartTime");

    require(
      _lockDuration >= minLockDuration && _lockDuration <= maxLockDuration,
      "!LockDuration"
    );

    require(msg.value >= getPrice(_lockDuration), "!price");

    uint256 newId = lastId + 1;
    require(newId <= maxSupply, "!MaxSupply");

    lastId = newId;
    lockDuration[newId] = _lockDuration;
    mintedAt[newId] = block.timestamp;

    _safeMint(msg.sender, newId);

    // mint KEYS to this contract
    uint256 keysToMint = KEYS_PER_NFT_PER_SECOND * _lockDuration;
    KEY.mint(keysToMint);

    // start flow of KEYS to the msg.sender
    _host.callAgreement(
      _cfa,
      abi.encodeWithSelector(
        _cfa.createFlow.selector,
        KEY,
        msg.sender,
        KEYS_PER_NFT_PER_SECOND,
        new bytes(0)
      ),
      "0x"
    );
  }

  function getPrice(uint256 _lockDuration) public view returns (uint256 price) {
    price =
      minPrice +
      ((maxPrice - minPrice) * (_lockDuration - minLockDuration)) /
      (maxLockDuration - minLockDuration);
  }

  function unLock(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender && !isUnlocked[tokenId]);

    uint256 keysToBurn = KEYS_PER_NFT_PER_SECOND * lockDuration[tokenId];
    KEY.burn(msg.sender, keysToBurn);

    // stop flow of KEYS to the msg.sender
    _host.callAgreement(
      _cfa,
      abi.encodeWithSelector(
        _cfa.deleteFlow.selector,
        KEY,
        address(this), // sender
        msg.sender, // receiver
        new bytes(0)
      ),
      "0x"
    );

    // TODO: burn the remaining KEYS now no longer owed to the user (if any)
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    require(isUnlocked[tokenId], "!Unlocked");

    super._transfer(from, to, tokenId);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function claimETH() external {
    (bool success, ) = owner().call{ value: address(this).balance }("");
    require(success);
  }
}
