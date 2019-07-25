pragma solidity ^0.5.0;

/// @title 提供检查传入签名有效性的帮助函数。
/// @author Noah Zinsmeister, Zaakin Yao
/// @dev 同时支持有前缀和无前缀的签名。
contract SignatureVerifier {
    /// @notice 校验传入的`messageHash`的签名是否由`_address`的私钥创建。
    /// @param _address 待校验的是否正确签名了`messageHash`的地址。
    /// @param messageHash 待校验的是否被正确签名的`messageHash`。
    /// @param v 签名的v值部分。
    /// @param r 签名的r值部分。
    /// @param s 签名的s值部分。
    /// @return 签名校验通过则返回 true 否则返回 false
    function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        return _isSigned(_address, messageHash, v, r, s) || _isSignedPrefixed(_address, messageHash, v, r, s);
    }

    /// @dev 校验消息未加前缀签名的内部函数。
    function _isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal pure returns (bool)
    {
        return ecrecover(messageHash, v, r, s) == _address;
    }

    /// @dev 校验消息加了前缀签名的内部函数。
    function _isSignedPrefixed(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal pure returns (bool)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return _isSigned(_address, keccak256(abi.encodePacked(prefix, messageHash)), v, r, s);
    }
}