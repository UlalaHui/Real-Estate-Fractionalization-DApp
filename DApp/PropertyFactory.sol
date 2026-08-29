// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PropertyToken.sol";

/**
 * @title PropertyFactory
 * @dev Deploys and tracks multiple PropertyToken contracts
 */
contract PropertyFactory {
    address[] public allProperties;
    mapping(address => address[]) public ownerToProperties;

    event PropertyCreated(
        address indexed propertyAddress,
        address indexed owner,
        string title,
        uint256 valuation,
        uint256 totalSupply,
        uint256 pricePerToken
    );

    /**
     * @dev Create a new PropertyToken
     */
    function createProperty(
        string memory _name,
        string memory _symbol,
        string memory _title,
        string memory _description,
        uint256 _valuation,
        uint256 _totalSupply,
        uint256 _pricePerToken,
        string memory _ipfsHash
    ) external returns (address) {
        PropertyToken newProperty = new PropertyToken(
            _name,
            _symbol,
            _title,
            _description,
            _valuation,
            _totalSupply,
            _pricePerToken,
            _ipfsHash,
            msg.sender
        );

        address propertyAddr = address(newProperty);

        allProperties.push(propertyAddr);
        ownerToProperties[msg.sender].push(propertyAddr);

        emit PropertyCreated(
            propertyAddr,
            msg.sender,
            _title,
            _valuation,
            _totalSupply,
            _pricePerToken
        );

        return propertyAddr;
    }

    /**
     * @dev Get all deployed property token addresses
     */
    function getAllProperties() external view returns (address[] memory) {
        return allProperties;
    }

    /**
     * @dev Get properties created by a specific owner
     */
    function getPropertiesByOwner(address _owner) external view returns (address[] memory) {
        return ownerToProperties[_owner];
    }

    /**
     * @dev Get the total number of properties
     */
    function getPropertiesCount() external view returns (uint256) {
        return allProperties.length;
    }
}
