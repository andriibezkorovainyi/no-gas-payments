//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Payments is Ownable {
    mapping (uint => bool) private nonces;
    event Claimed(address indexed recipient, uint amount, uint nonce, address indexed owner);

    constructor() Ownable(_msgSender()) payable {
         require(msg.value > 0);
    }

    function claim(uint amount, uint nonce, bytes memory signature) external {
        require(!nonces[nonce], "Nonce has already been used");
        nonces[nonce] = true;

        bytes32 message = prefixed(
            keccak256(abi.encodePacked(msg.sender, amount, nonce, address(this)))
        );

        address signer = recoverSigner(message, signature);
        require(signer == owner(), "Invalid signature");

        payable(msg.sender).transfer(amount);
        emit Claimed(msg.sender, amount, nonce, owner());
    }

    function recoverSigner(bytes32 message, bytes memory sig) pure internal returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) pure internal returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}