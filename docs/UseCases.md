# IDHub DID-Plus On-Chain UseCases

IDHub DID-Plus采用ERC1056标示用户去中心化数字身份，并在后续根据DID协议进行扩展；另外，采用ERC1484对用户在以太坊上的数字身份进行聚合。在此用例中，ERC1056`identity`和ERC1484`EIN`同时作为用户的去中心化数字身份标识符。

## 身份管理

ERC1484提供了身份创建、恢复`EIN`，ERC1056默认自动为用户注册`identity`。

### 身份创建
在ERC1484调用`createIdentity`函数或者通过授权签名调用`createIdentityDelegated`函数获得`EIN`，在ERC1056中会默认将以太坊交易发起地址或授权签名地址注册为`identity`

```solidity
	// ERC1484创建身份
	function createIdentity(address recoveryAddress, address[] memory providers, address[] memory resolvers)
        public returns (uint ein)

	// 或者采用授权签名的方式注册身份
	function createIdentityDelegated(
        address recoveryAddress, address associatedAddress, address[] memory providers, address[] memory resolvers,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    )
        public ensureSignatureTimeValid(timestamp) returns (uint ein)

    // ERC1056会默认注册创建身份
    function identityOwner(address identity) public view returns(address) {
        address owner = owners[identity];
        if (owner != address(0)) {
            return owner;
        }
        return identity;
    }
```
`createIdentity`的交易发起地址为`associatedAddress`或者`createIdentityDelegated`函数的`v, r, s`参数值来自于参数`associatedAddress`的签名。在创建身份步骤里，前面所述的`associatedAddress`会在ERC1056中默认被注册为`identity`。恢复地址`recoveryAddress`对应的私钥应该被冷存储用于特殊情况发生时找回`EIN`的控制权。

### 身份找回

身份的找回主要依靠恢复地址的使用。

#### 更改恢复地址

关联地址可以通过调用`triggerRecoveryAddressChange`函数来更改恢复地址。
```solidity
    function triggerRecoveryAddressChange(address newRecoveryAddress) public
```
新的恢复地址需要两周才生效，原恢复地址有权利在两周内直接触发身份恢复流程来找回身份，参考下一节，此权限适用于身份被盗用且触发了更改恢复地址的流程。

#### 身份恢复

恢复地址或更改恢复地址流程触发两周内的原恢复地址可以调用`triggerRecovery`触发身份恢复流程来找回`EIN`的控制权。
```solidity
    function triggerRecovery(uint ein, address newAssociatedAddress, uint8 v, bytes32 r, bytes32 s, uint timestamp)
        public _identityExists(ein) _hasIdentity(newAssociatedAddress, false) ensureSignatureTimeValid(timestamp)
```
此操作会删除`EIN`所有的关联地址、`Provider`和`Resolver`，传入的`newAssociatedAddress`参数需要未和任何`EIN`绑定过关联关系且会成为`EIN`的唯一关联地址。另外，还需要`newAssociatedAddress`的签名`v, r, s`值。

### 身份注销

用户在发现关联地址或者恢复地址被盗用且触发恢复流程的两周内，可以强制注销身份。
```solidity
    function triggerDestruction(uint ein, address[] memory firstChunk, address[] memory lastChunk, bool resetResolvers)
        public _identityExists(ein)
```
此操作的交易发起者必须是`EIN`的关联地址之一，且要严格按序传入`EIN`的所有关联地址，包括交易发起者之前的关联地址数组和之后的关联地址数组。因此，必要的时候用户应该按序保存所有关联地址或注销身份时读取关联地址的排序来构建参数。

## 密钥轮换管理

ERC1484提供了将多个关联地址`associatedAddress`映射到同一个`EIN`的功能。

## 链上申明验证