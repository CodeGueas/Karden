// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// https://etherscan.io/address/0x6d2ab95fbdf722e5840379dbd59b0979b3ad2fbb

contract KardNFT is ERC1155URIStorageUpgradeable, OwnableUpgradeable {
    event KardCreate(address creator, uint256 kardId);

    uint256 nextkardId;

    uint256 public rate;
    uint256 public base;

    struct Kard {
        address creator;
        uint256 price;
        bool isLimited;
        uint256 quantity;
        string uri;
    }

    mapping(uint256 => Kard) private kards;

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();

        rate = 30;
        base = 100;
    }

    function createKard(
        string memory _uri,
        uint256 price,
        bool _isLimited,
        uint256 quantity
    ) public returns (uint256) {
        require(bytes(_uri).length > 0, "Kard: ERR_EMPTY_URI");
        require(_isLimited == false || quantity > 0, "Kard: ERR_QUANTITY");

        uint256 kardId = nextkardId++;
        Kard storage kard = kards[kardId];

        kard.creator = msg.sender;
        kard.uri = _uri;
        kard.price = price;
        kard.isLimited = _isLimited;
        kard.quantity = quantity;

        emit KardCreate(msg.sender, kardId);

        return kardId;
    }

    function mintKard(address to, uint256 kardId) public payable {
        Kard storage kard = kards[kardId];

        require(kard.creator != address(0), "Kard: ERR_KARD_NOT_EXISTS");
        require(kard.price <= msg.value, "Kard: ERR_INSUFFICIENT_FUNDS");
        require(
            kard.isLimited == false || kard.quantity > 0,
            "Kard: ERR_QUANTITY_NOT_ENOUHH"
        );

        _mint(to, kardId, 1, "");
        if (kard.isLimited) {
            kard.quantity--;
        }

        if (kard.price > 0) {
            payable(kard.creator).transfer(
                msg.value - (msg.value * rate) / base
            );
        }
    }

    function upgradeKard(uint256 kardId, string memory _uri) public {
        Kard storage kard = kards[kardId];

        require(kard.creator == msg.sender, "Kard: ERR_NOT_CREATOR");
        require(bytes(_uri).length > 0, "Kard: ERR_EMPTY_URI");

        kard.uri = _uri;

        emit URI(_uri, kardId);
    }

    function uri(uint256 kardId) public view override returns (string memory) {
        return kards[kardId].uri;
    }

    function kardDetail(uint256 kardId) public view returns (Kard memory) {
        return kards[kardId];
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Kard: ERR_OVER");
    }

    function setRate(uint256 _rate, uint256 _base) public onlyOwner {
        require(_rate < _base, "Kard: ERR_RATE_GREATER_THEN_BASE");

        rate = _rate;
        base = _base;
    }
}
