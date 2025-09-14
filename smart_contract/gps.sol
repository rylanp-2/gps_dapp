// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


contract GPS {

    address private immutable user;

    uint256 public timestamp;

    bytes public encryptedCoords;

    constructor() {
        // Set the autorized user as the address that deploys the contract
        user = msg.sender;
    }

    modifier authorizedCaller() {
        // Check that the caller is the authorized user
        require(msg.sender == user, "Unauthorized caller");
        _;
    }

    function updateLocation(bytes calldata payload) public authorizedCaller() {
        encryptedCoords = payload;
        timestamp = block.timestamp;
    }

    function readLocation() public view returns (bytes memory, uint256) {
        return(encryptedCoords, timestamp);
    }

}