## 签名验证

### 背景（以太坊签名方案）

对于以太坊的最佳签名方案有大量讨论，典型的像是否应该包含[`\x19Ethereum Signed Message:\n<length of message>`](https://ethereum.stackexchange.com/questions/19582/does-ecrecover-in-solidity-expects-the-x19ethereum-signed-message-n-prefix)前缀等。对于本文件/ERC1484而言：
* 应该只签名消息的哈希值，而不应该签名原始消息。这样可以直接在EVM中验签，比如：
```solidity
  bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, "123", 100))
  address signingAddress = ecrecover(messageHash, v, r, s);  
```
* 应该使用[ERC191签名方案](https://github.com/ethereum/EIPs/issues/191)构建签名，这可以确保用户不会误签名一个RLP编码的以太坊交易，也可以确保在[ERC191方案中的版本特定数据]()中指定当前交互的合约，也就是`address(this)`，示例：

```solidity
function submitTransactionPreSigned(address destination, uint value, bytes data, uint nonce, uint8 v, bytes32 r, bytes32 s)
    public
    returns (bytes32 transactionHash)
{
   // Arguments when calculating hash to validate
    // 1: byte(0x19) - the initial 0x19 byte
    // 2: byte(0) - the version byte 
    // 4: this - the validator address
    // 4-7 : Application specific data
    transactionHash = keccak256(byte(0x19),byte(0),this,destination, value, data, nonce);
    sender = ecrecover(transactionHash, v, r, s);
    // ...
}
```
* 为了改进消息哈希签名的用户体验，可信任的用户界面可以向用户显示他们正在要被哈希签名的数据，这将是一个很大的改进，唯一剩下的问题是无法验证数据的字段名称（在用户签署包含多个地址的数据的情况下导致潜在的混淆/误导，比如一个`to`和一个`from`地址等）。最近，例如[ERC-712](https://github.com/ethereum/EIPs/pull/712)旨在通过对智能合约中的值进行硬编码来解决该问题，以实现复杂的前端签名验证。

* 不建议在签名消息中加入以太坊官方签名消息的前缀`\x19Ethereum Signed Message:\n<length of message>`，这一点应该是可选的，但如果选择了则应该在加入前缀之前先哈希消息，然后加入前缀再次哈希，最后再签名，示例如下：
```solidity
  bytes prefix = "\x19Ethereum Signed Message:\n32";
  bytes32 innerHash = keccak256(abi.encodePacked(...));
  bytes32 messageHash = keccak256(abi.encodePacked(prefix, innerHash));
```

### 防止重放攻击
通常，可能会使用一定的技术手段通过用户签名实现一些权限调用，比如`Providers`，签名授权的使用中必须要注意重放攻击，强烈建议使用以下四种策略之一或组合来防止重放攻击。

### 1. 设计签名唯一性
技术上最难但概念上最简单的解决方案是简单地确保给定的签名在设计上只能使用一次。这对于一次性注册情况是理想的，其中正在签名的内容阻止签名再次被使用。

### 2. 强制签名唯一性
如果无法通过设计实现唯一性，则可以通过两种方式强制执行：

#### 限时
每次一个地址调用允许的函数时，它们所签署的消息中必须包含一个时间戳，该时间戳在当前区块时间戳的某个延后间隔期内。

* 优点：不需要链上存储或链上读/写。
* 缺点：签名可以在短窗口期内重放，可能会在区块交易时间附近引入脆弱性，区块时间戳可能会被矿工略微操纵。 

#### 随机数（`nonce`）
每当一个地址调用允许的函数时，它们的消息必须包含一个每个调用会自增的`nonce`值。

* 优点：相对较少的gas成本（仅需约5k gas 来更新现有的存储变量）
* 缺点：需要对每个事务进行链上读写。有多个待打包交易可能会引入脆弱性。