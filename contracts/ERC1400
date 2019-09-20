pragma solidity ^0.5.0;


import "./IERC1400.sol";
import "./SafeMath.sol";
import "./whitelist.sol";


/**
 * @title ERC1400
 * @dev ERC1400 logic
 */
contract ERC1400 is IERC1400  {
    
  whitelist wl;    
    
  using SafeMath for uint256;  
  
  string internal _name;
  
  string internal _symbol;
  
  uint256 internal _granularity;
  
  uint256 internal _decimals;
  
  uint256 internal _totalSupply;
  
  address public owner;

  struct Doc {
    string docURI;
    bytes32 docHash;
  }
  
  // List of partitions.
  bytes32[] internal _totalPartitions;

  // Mapping for token URIs.
  mapping(bytes32 => Doc) internal _documents;
  
  // Mapping from tokenHolder to balance.
  mapping(address => uint256) internal _balances;
  
  // Mapping from (tokenHolder, partition) to their index.
  mapping (address => mapping (bytes32 => uint256)) internal _indexOfPartitionsOf;
  
  // Mapping from partition to their index.
  mapping (bytes32 => uint256) internal _indexOfTotalPartitions;
  
  // Mapping from tokenHolder to their partitions.
  mapping (address => bytes32[]) internal _partitionsOf;
  
  // Mapping from (tokenHolder, partition) to balance of corresponding partition.
  mapping (address => mapping (bytes32 => uint256)) internal _balanceOfByPartition;
  
  // Mapping from partition to global balance of corresponding partition.
  mapping (bytes32 => uint256) internal _totalSupplyByPartition;
  // Mapping from (operator, tokenHolder) to authorized status. [TOKEN-HOLDER-SPECIFIC]
  mapping(address => mapping(address => bool)) internal _authorizedOperator;
  // Array of controllers. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
  address[] internal _controllers;
  
  // Mapping from (tokenHolder, partition, operator) to 'approved for partition' status. [TOKEN-HOLDER-SPECIFIC]
  mapping (address => mapping (bytes32 => mapping (address => bool))) internal _authorizedOperatorByPartition;
  
  // Mapping from (partition, operator) to PartitionController status. [NOT TOKEN-HOLDER-SPECIFIC]
  mapping (bytes32 => mapping (address => bool)) internal _isControllerByPartition;
  // Mapping from operator to controller status. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
  mapping(address => bool) internal _isController;
  // Mapping from partition to controllers for the partition. [NOT TOKEN-HOLDER-SPECIFIC]
  mapping (bytes32 => address[]) internal _controllersByPartition;

  // Indicate whether the token can still be issued by the issuer or not anymore.
  bool public _isIssuable;
  // Indicate whether the token can still be controlled by operators or not anymore.
  bool public _isControllable;
//   //Calculating the Locking Period
//   uint256 public Lockdata;
//   //this mapping about partitions <==> Lockdata 
//   mapping (bytes32 => uint256) internal _PartitionwithLock;

  /**
   * @dev Modifier to verify if token is issuable. 
   */
  modifier issuableToken() {
    require(_isIssuable, "A8"); // Transfer Blocked - Token restriction
    _;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
  * [ERC1400 CONSTRUCTOR]
  * @dev Initialize ERC1400 + register
  * the contract implementation in ERC1820Registry.
  * @param name Name of the token.
  * @param symbol Symbol of the token.
  * @param controllers Array of initial controllers.
  */
  constructor(
    string memory name,
    string memory symbol,
    uint256 decimals,
    address[] memory controllers,
    address  whitelistaddr
  )
    public
  {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _granularity = 10**(decimals);
    _isControllable = true;
    _isIssuable = true;
    owner = msg.sender;
    _totalSupply = 0;
    wl = whitelist(whitelistaddr);
    _controllers = controllers;
  }

  /********************** ERC1400 EXTERNAL FUNCTIONS **************************/
  /**
   * @dev Get the name of the token, e.g., "MyToken".
   * @return Name of the token.
   */
  function name() external view returns(string memory) {
    return _name;
  }

  /**
   * @dev Get the symbol of the token, e.g., "MYT".
   * @return Symbol of the token.
   */
  function symbol() external view returns(string memory) {
    return _symbol;
  }
 /**
   * @dev Get the decimals of the token
   * @return decimals of the token.
   */
  function decimals() external view returns(uint256) {
    return _decimals;
  }

  /**
   * @dev Get the total number of issued tokens.
   * @return Total supply of tokens currently in circulation.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }
  /**
   * @dev Get the smallest part of the token that’s not divisible.
   * @return The smallest non-divisible part of the token.
   */
  function granularity() external view returns(uint256) {
    return _granularity;
  }
  /**
   * @dev Get the list of controllers as defined by the token contract.
   * @return List of addresses of all the controllers.
   */
  function controllers() external view returns (address[] memory) {
    return _controllers;
  }
  /**
  * @dev Access a document associated with the token.
  * @param _name Short name (represented as a bytes32) associated to the document.
  * @return Requested document + document hash.
  */
  function getDocument(bytes32 _name) external view returns (string memory, bytes32) {
    require(bytes(_documents[_name].docURI).length != 0); // Action Blocked - Empty document
    return (
      _documents[_name].docURI,
      _documents[_name].docHash
    );
  }

  /**
  * @dev Associate a document with the token.
  * @param _name Short name (represented as a bytes32) associated to the document.
  * @param _uri Document content.
  * @param _documentHash Hash of the document [optional parameter].
  */
  function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external {
    require(_isController[msg.sender]);
    _documents[_name] = Doc({
      docURI: _uri,
      docHash: _documentHash
    });
    emit Document(_name, _uri, _documentHash);
  }
  /**
  * @dev Get balance of a tokenholder for a specific partition.
  * @param _partition Name of the partition.
  * @param _tokenHolder Address for which the balance is returned.
  * @return Amount of token of partition '_partition' held by '_tokenHolder' in the token contract.
  */
  function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns (uint256) {
    return _balanceOfByPartition[_tokenHolder][_partition];
  }
  /**
  * @dev Get partitions index of a tokenholder.
  * @param _tokenHolder Address for which the partitions index are returned.
  * @return Array of partitions index of 'tokenHolder'.
  */
  function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory) {
    return _partitionsOf[_tokenHolder];
  }
  /**
  * @dev Transfer tokens from a specific partition.
  * @param _partition Name of the partition.
  * @param _to Token recipient.
  * @param _value Number of tokens to transfer.
  * @param _data Information attached to the transfer, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
  * @return Destination partition.
  */
  function transferByPartition(bytes32 _partition,address _to,uint256 _value,bytes calldata _data) external returns (bytes32) {
    return _transferByPartition(_partition, msg.sender, msg.sender,_to,_value,_data, "",true);
  }
  /**
  * @dev Transfer tokens from a specific partition through an operator.
  * @param _partition Name of the partition.
  * @param _from Token holder.
  * @param _to Token recipient.
  * @param _value Number of tokens to transfer.
  * @param _data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
  * @param _operatorData Information attached to the transfer, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
  * @return Destination partition.
  */
  function operatorTransferByPartition(
    bytes32 _partition,
    address _from,
    address _to,
    uint256 _value,
    bytes calldata _data,
    bytes calldata _operatorData
  )
    external
    returns (bytes32)
  {
    require(_isOperatorForPartition(_partition, msg.sender, _from), "A7"); // Transfer Blocked - Identity restriction

    return _transferByPartition(_partition, msg.sender, _from, _to, _value, _data, _operatorData, true);
  }
  /**
  * @dev Know if the token can be controlled by operators.
  * If a token returns 'false' for 'isControllable()'' then it MUST always return 'false' in the future.
  * @return bool 'true' if the token can still be controlled by operators, 'false' if it can't anymore.
  */
  function isControllable() external view returns (bool) {
    return _isControllable;
  }
 /**
  * 
  * 
  * 
  */
  function controllerTransfer(bytes32 _partition,address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external onlyOwner{
    if (_balanceOfByPartition[_from][_partition] < _value) {
        uint256 tovalue = _balanceOfByPartition[_from][_partition];
        _removeTokenFromPartition(_from, _partition,tovalue);
        _addTokenToPartition(_to, _partition, tovalue);
    }else{
        _removeTokenFromPartition(_from, _partition,_value);
        _addTokenToPartition(_to, _partition, _value);    
    }
     emit ControllerTransfer(msg.sender,_from,_to,_value,_data,_operatorData);
  }
  function controllerRedeem(bytes32 _partition,address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external onlyOwner{
    if (_balanceOfByPartition[_tokenHolder][_partition] < _value){
         uint256 tovalue = _balanceOfByPartition[_tokenHolder][_partition];
         _removeTokenFromPartition(_tokenHolder, _partition,tovalue);
         _redeem(_partition, msg.sender,_tokenHolder, tovalue, _data, _operatorData);    
    }else{
        _removeTokenFromPartition(_tokenHolder, _partition,_value);
        _redeem(_partition, msg.sender,_tokenHolder, _value, _data, _operatorData);     
    }
    emit ControllerRedemption(msg.sender,_tokenHolder,_value,_data,_operatorData);
  }
  
  /**
  * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
  * and redeem tokens on its behalf.
  * @param _operator Address to set as an operator for 'msg.sender'.
  */
  function authorizeOperator(address _operator) external {
    require(_operator != msg.sender);
    _authorizedOperator[_operator][msg.sender] = true;
    emit AuthorizedOperator(_operator, msg.sender);
  }
  /**
  * @dev Remove the right of the operator address to be an operator for 'msg.sender'
  * and to transfer and redeem tokens on its behalf.
  * @param _operator Address to rescind as an operator for 'msg.sender'.
  */
  function revokeOperator(address _operator) external {
    require(_operator != msg.sender);
    _authorizedOperator[_operator][msg.sender] = false;
    emit RevokedOperator(_operator, msg.sender);
  }
  /**
  * @dev Set 'operator' as an operator for 'msg.sender' for a given partition.
  * @param _partition Name of the partition.
  * @param _operator Address to set as an operator for 'msg.sender'.
  */
  function authorizeOperatorByPartition(bytes32 _partition, address _operator) external {
    _authorizedOperatorByPartition[msg.sender][_partition][_operator] = true;
    emit AuthorizedOperatorByPartition(_partition,_operator, msg.sender);
  }
  /**
  * @dev Remove the right of the operator address to be an operator on a given
  * partition for 'msg.sender' and to transfer and redeem tokens on its behalf.
  * @param _partition Name of the partition.
  * @param _operator Address to rescind as an operator on given partition for 'msg.sender'.
  */
  function revokeOperatorByPartition(bytes32 _partition, address _operator) external {
    _authorizedOperatorByPartition[msg.sender][_partition][_operator] = false;
    emit RevokedOperatorByPartition(_partition, _operator, msg.sender);
  }
  /**
  * @dev Indicate whether the operator address is an operator of the tokenHolder address.
  * @param _operator Address which may be an operator of tokenHolder.
  * @param _tokenHolder Address of a token holder which may have the operator address as an operator.
  * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
  */
  function isOperator(address _operator, address _tokenHolder) external view returns (bool) {
    return _isOperator(_operator, _tokenHolder);
  }
  /**
  * @dev Indicate whether the operator address is an operator of the tokenHolder
  * address for the given partition.
  * @param _partition Name of the partition.
  * @param _operator Address which may be an operator of tokenHolder for the given partition.
  * @param _tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
  * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
  */
  function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool) {
    return _isOperatorForPartition(_partition, _operator, _tokenHolder);
  }
  /**
  * @dev Know if new tokens can be issued in the future.
  * @return bool 'true' if tokens can still be issued by the issuer, 'false' if they can't anymore.
  */
  function isIssuable() external view returns (bool) {
    return _isIssuable;
  }

  /**
  * @dev Issue tokens from a specific partition.
  * @param _partition Name of the partition.
  * @param _tokenHolder Address for which we want to issue tokens.
  * @param _value Number of tokens issued.
  * @param _data Information attached to the issuance, by the issuer. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
  * @param _Day is Lockdata.
  */
  function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data,uint _Day)
    external
    onlyOwner
  {
    // Lockdata = wl.getdata(_Day);
    // _PartitionwithLock[_partition] = Lockdata;
    require(wl.FindPersonal(_tokenHolder) == true);  
    _issueByPartition(_partition, msg.sender,_tokenHolder,_value,_data, "");
  }
  /**
  * @dev Redeem tokens of a specific partition.
  * @param _partition Name of the partition.
  * @param _value Number of tokens redeemed.
  * @param _data Information attached to the redemption, by the redeemer. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
  */
  function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data)
    external
  {
    _redeemByPartition(_partition, msg.sender, msg.sender,_value,_data, "");
  }

  /**
  * @dev Redeem tokens of a specific partition.
  * @param _partition Name of the partition.
  * @param _tokenHolder Address for which we want to redeem tokens.
  * @param _value Number of tokens redeemed.
  * @param _data Information attached to the redemption.
  * @param _operatorData Information attached to the redemption, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
  */
  function operatorRedeemByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData)
    external
  {
    require(_isOperatorForPartition(_partition, msg.sender, _tokenHolder), "A7"); // Transfer Blocked - Identity restriction

    _redeemByPartition(_partition, msg.sender,_tokenHolder,_value,_data,_operatorData);
  }

  /**
  * @dev Know the reason on success or failure based on the EIP-1066 application-specific status codes.
  * @param _partition Name of the partition.
  * @param _to Token recipient.
  * @param _value Number of tokens to transfer.
  * @param _data Information attached to the transfer, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
  * @return ESC (Ethereum Status Code) following the EIP-1066 standard.
  * @return Additional bytes32 parameter that can be used to define
  * application specific reason codes with additional details (for example the
  * transfer restriction rule responsible for making the transfer operation invalid).
  * @return Destination partition. 
  */
  function canTransferByPartition(bytes32 _partition,address _from,address _to, uint256 _value, bytes calldata _data)
    external
    view
    returns (byte, bytes32, bytes32)
  {
    return _canTransfer(_partition, msg.sender, msg.sender,_to,_value,_data, "");
    
  }
  /**
  * @dev Know the reason on success or failure based on the EIP-1066 application-specific status codes.
  * @param _partition Name of the partition.
  * @param _from Token holder.
  * @param _to Token recipient.
  * @param _value Number of tokens to transfer.
  * @param _data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
  * @param _operatorData Information attached to the transfer, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
  * @return ESC (Ethereum Status Code) following the EIP-1066 standard.
  * @return Additional bytes32 parameter that can be used to define
  * application specific reason codes with additional details (for example the
  * transfer restriction rule responsible for making the transfer operation invalid).
  * @return Destination partition.
  */
  function canOperatorTransferByPartition(bytes32 _partition, address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData)
    external
    view
    returns (byte, bytes32, bytes32)
  {
    return _canTransfer(_partition,msg.sender,_from,_to,_value,_data,_operatorData);
  }
  /********************** ERC1400 INTERNAL FUNCTIONS **************************/
  /**
  * [INTERNAL]
  * @dev Check if 'value' is multiple of the granularity.
  * @param _value The quantity that want's to be checked.
  * @return 'true' if 'value' is a multiple of the granularity.
  */
  function _isMultiple(uint256 _value) internal view returns(bool) {
    return(_value.div(_granularity).mul(_granularity) == _value);
  }

  /**
  * [INTERNAL]
  * @dev Know the reason on success or failure based on the EIP-1066 application-specific status codes.
  * @param _partition Name of the partition.
  * @param _operator The address performing the transfer.
  * @param _from Token holder.
  * @param _to Token recipient.
  * @param _value Number of tokens to transfer.
  * @param _data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
  * @param _operatorData Information attached to the transfer, by the operator (if any).
  * @return ESC (Ethereum Status Code) following the EIP-1066 standard.
  * @return Additional bytes32 parameter that can be used to define
  * application specific reason codes with additional details (for example the
  * transfer restriction rule responsible for making the transfer operation invalid).
  * @return Destination partition.
  */
  function _canTransfer(bytes32 _partition, address _operator, address _from, address _to, uint256 _value, bytes memory _data, bytes memory _operatorData)
     internal
     view
     returns (byte, bytes32, bytes32)
  {
    require(wl.FindPersonal(_from) == true,"need KYC verify");  
    require(wl.FindPersonal(_to) == true,"need KYC verify");
     if(!_isOperatorForPartition(_partition, _operator, _from))
      return(hex"A7", "", _partition); // "Transfer Blocked - Identity restriction"

     if((_balanceOfByPartition[_from][_partition] < _value))
      return(hex"A4", "", _partition); // Transfer Blocked - Sender balance insufficient

     if(_to == address(0))
      return(hex"A6", "", _partition); // Transfer Blocked - Receiver not eligible

     if(!_isMultiple(_value))
      return(hex"A9", "", _partition); // Transfer Blocked - Token granularity

     return(hex"A2", "", _partition);  // Transfer Verified - Off-Chain approval for restricted token
  }

  /**
  * [INTERNAL]
  * @dev Issue tokens from a specific partition.
  * @param _toPartition Name of the partition.
  * @param _operator The address performing the issuance.
  * @param _to Token recipient.
  * @param _value Number of tokens to issue.
  * @param _data Information attached to the issuance.
  * @param _operatorData Information attached to the issuance, by the operator (if any).
  */
  function _issueByPartition(
    bytes32 _toPartition,
    address _operator,
    address _to,
    uint256 _value,
    bytes memory _data,
    bytes memory _operatorData
  )
    internal
  {
    _issue(_toPartition, _operator, _to, _value, _data, _operatorData);
    _addTokenToPartition(_to, _toPartition, _value);

    emit IssuedByPartition(_toPartition, _operator, _to, _value, _data, _operatorData);
  }
  /**
  * [INTERNAL]
  * @dev Perform the issuance of tokens.
  * @param _partition Name of the partition (bytes32 to be left empty for ERC1400Raw transfer).
  * @param _operator Address which triggered the issuance.
  * @param _to Token recipient.
  * @param _value Number of tokens issued.
  * @param _data Information attached to the issuance, and intended for the recipient (to).
  * @param _operatorData Information attached to the issuance by the operator (if any).
  */
  function _issue(bytes32 _partition, address _operator, address _to, uint256 _value, bytes memory _data, bytes memory _operatorData) internal {
    require(_isMultiple(_value), "A9"); // Transfer Blocked - Token granularity
    require(_to != address(0), "A6"); // Transfer Blocked - Receiver not eligible

    _totalSupply = _totalSupply.add(_value);
    _balances[_to] = _balances[_to].add(_value);
    
    //emit Issued(operator, to, value, data, operatorData);
    emit Issued(_operator, _to, _value, _data);
  }
  /**
  * [INTERNAL]
  * @dev Add a token to a specific partition. //向特定分区添加令牌。
  * @param _to Token recipient.
  * @param _partition Name of the partition.
  * @param _value Number of tokens to transfer.
  */
  function _addTokenToPartition(address _to, bytes32 _partition, uint256 _value) internal {
    if(_value != 0) {
      if (_indexOfPartitionsOf[_to][_partition] == 0) {
        _partitionsOf[_to].push(_partition);
        _indexOfPartitionsOf[_to][_partition] = _partitionsOf[_to].length;
      }
      _balanceOfByPartition[_to][_partition] = _balanceOfByPartition[_to][_partition].add(_value);

      if (_indexOfTotalPartitions[_partition] == 0) {
        _totalPartitions.push(_partition);
        _indexOfTotalPartitions[_partition] = _totalPartitions.length;
      }
      _totalSupplyByPartition[_partition] = _totalSupplyByPartition[_partition].add(_value);
    }
  }

  /**
  * [INTERNAL]
  * @dev Redeem tokens of a specific partition.
  * @param _fromPartition Name of the partition.
  * @param _operator The address performing the redemption.
  * @param _from Token holder whose tokens will be redeemed.
  * @param _value Number of tokens to redeem.
  * @param _data Information attached to the redemption.
  * @param _operatorData Information attached to the redemption, by the operator (if any).
  */
  function _redeemByPartition(
    bytes32 _fromPartition,
    address _operator,
    address _from,
    uint256 _value,
    bytes memory _data,
    bytes memory _operatorData
  )
    internal
  {
    require(_balanceOfByPartition[_from][_fromPartition] >= _value, "A4"); // Transfer Blocked - Sender balance insufficient

    _removeTokenFromPartition(_from,_fromPartition,_value);
    _redeem(_fromPartition,_operator,_from,_value,_data,_operatorData);

    //emit RedeemedByPartition(fromPartition, operator, from, value, data, operatorData);
    emit RedeemedByPartition(_fromPartition,_operator,_from,_value,_operatorData);
  }
  /**
  * [INTERNAL]
  * @dev Remove a token from a specific partition.
  * @param _from Token holder.
  * @param _partition Name of the partition.
  * @param _value Number of tokens to transfer.
  */
  function _removeTokenFromPartition(address _from, bytes32 _partition, uint256 _value) internal {
    _balanceOfByPartition[_from][_partition] = _balanceOfByPartition[_from][_partition].sub(_value);
    _totalSupplyByPartition[_partition] = _totalSupplyByPartition[_partition].sub(_value);

    // If the total supply is zero, finds and deletes the partition.
    if(_totalSupplyByPartition[_partition] == 0) {
      uint256 index1 = _indexOfTotalPartitions[_partition];
      require(index1 > 0, "A8"); // Transfer Blocked - Token restriction

      // move the last item into the index being vacated
      bytes32 lastValue = _totalPartitions[_totalPartitions.length - 1];
      _totalPartitions[index1 - 1] = lastValue; // adjust for 1-based indexing
      _indexOfTotalPartitions[lastValue] = index1;

      _totalPartitions.length -= 1;
      _indexOfTotalPartitions[_partition] = 0;
    }

    // If the balance of the TokenHolder's partition is zero, finds and deletes the partition.
    if(_balanceOfByPartition[_from][_partition] == 0) {
      uint256 index2 = _indexOfPartitionsOf[_from][_partition];
      require(index2 > 0, "A8"); // Transfer Blocked - Token restriction

      // move the last item into the index being vacated
      bytes32 lastValue = _partitionsOf[_from][_partitionsOf[_from].length - 1];
      _partitionsOf[_from][index2 - 1] = lastValue;  // adjust for 1-based indexing
      _indexOfPartitionsOf[_from][lastValue] = index2;

      _partitionsOf[_from].length -= 1;
      _indexOfPartitionsOf[_from][_partition] = 0;
    }
  }
    /**
  * [INTERNAL]
  * @dev Perform the token redemption.
  * @param _partition Name of the partition (bytes32 to be left empty for ERC1400Raw transfer).
  * @param _operator The address performing the redemption.
  * @param _from Token holder whose tokens will be redeemed.
  * @param _value Number of tokens to redeem.
  * @param _data Information attached to the redemption.
  * @param _operatorData Information attached to the redemption, by the operator (if any).
  */
  function _redeem(bytes32 _partition, address _operator, address _from, uint256 _value, bytes memory _data, bytes memory _operatorData)
    internal
  {
    require(_isMultiple(_value), "A9"); // Transfer Blocked - Token granularity
    require(_from != address(0), "A5"); // Transfer Blocked - Sender not eligible
    require(_balances[_from] >= _value, "A4"); // Transfer Blocked - Sender balance insufficient

    _balances[_from] = _balances[_from].sub(_value);
    _totalSupply = _totalSupply.sub(_value);

    //emit Redeemed(operator, from, value, data, operatorData);
    emit Redeemed(_operator,_from,_value,_data);
  }
  /**
  * [INTERNAL]
  * @dev Indicate whether the operator address is an operator of the tokenHolder
  * address for the given partition.
  * @param _partition Name of the partition.
  * @param _operator Address which may be an operator of tokenHolder for the given partition.
  * @param _tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
  * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
  */
  function _isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) internal view returns (bool) {
     return (_isOperator(_operator,_tokenHolder)
      || _authorizedOperatorByPartition[_tokenHolder][_partition][_operator]
      || (_isControllable && _isControllerByPartition[_partition][_operator])
     );
  }
   
  /**
  * [INTERNAL]
  * @dev Transfer tokens from a specific partition.
  * @param _fromPartition Partition of the tokens to transfer.
  * @param _operator The address performing the transfer.
  * @param _from Token holder.
  * @param _to Token recipient.
  * @param _value Number of tokens to transfer.
  * @param _data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
  * @param _operatorData Information attached to the transfer, by the operator (if any).
  * @param _preventLocking 'true' if you want this function to throw when tokens are sent to a contract not
  * implementing 'erc777tokenHolder'.
  * @return Destination partition.
  */
  function _transferByPartition(
    bytes32 _fromPartition,
    address _operator,
    address _from,
    address _to,
    uint256 _value,
    bytes memory _data,
    bytes memory _operatorData,
    bool _preventLocking
  )
    internal
    returns (bytes32)
  {
    require(wl.FindPersonal(_from) == true);
    require(wl.FindPersonal(_to) == true);
    // require(now >=Lockdata);
    require(_balanceOfByPartition[_from][_fromPartition] >= _value, "A4"); // Transfer Blocked - Sender balance insufficient

    bytes32 toPartition = _fromPartition;

    _removeTokenFromPartition(_from, _fromPartition, _value);
    _addTokenToPartition(_to, toPartition, _value);

    emit TransferByPartition(_fromPartition, _operator, _from, _to, _value, _data, _operatorData);

    if(toPartition != _fromPartition) {
      emit ChangedPartition(_fromPartition, toPartition, _value);
    }

    return toPartition;
  }
  /**
  * [INTERNAL]
  * @dev Indicate whether the operator address is an operator of the tokenHolder address.
  * @param _operator Address which may be an operator of 'tokenHolder'.
  * @param _tokenHolder Address of a token holder which may have the 'operator' address as an operator.
  * @return 'true' if 'operator' is an operator of 'tokenHolder' and 'false' otherwise.
  */
  function _isOperator(address _operator, address _tokenHolder) internal view returns (bool) {
    return (_operator == _tokenHolder
      || _authorizedOperator[_operator][_tokenHolder]
      || (_isControllable && _isController[_operator])
    );
  }
 /**
  * [NOT MANDATORY FOR ERC1400Raw STANDARD]
  * @dev Set list of token controllers.
  * @param _operators Controller addresses.
  */
  function _setControllers(address[] memory _operators) internal {
    for (uint i = 0; i<_controllers.length; i++){
      _isController[_controllers[i]] = false;
    }
    for (uint j = 0; j<_operators.length; j++){
      _isController[_operators[j]] = true;
    }
    _controllers = _operators;
  }
 /**
  * [NOT MANDATORY FOR ERC1400Partition STANDARD][SHALL BE CALLED ONLY FROM ERC1400]
  * @dev Set list of token partition controllers.
  * @param _partition Name of the partition.
  * @param _operators Controller addresses.
  */
  function _setPartitionControllers(bytes32 _partition, address[] memory _operators) internal {
     for (uint i = 0; i<_controllersByPartition[_partition].length; i++){
      _isControllerByPartition[_partition][_controllersByPartition[_partition][i]] = false;
     }
     for (uint j = 0; j<_operators.length; j++){
      _isControllerByPartition[_partition][_operators[j]] = true;
     }
     _controllersByPartition[_partition] = _operators;
  }
  /********************** ERC1400 OPTIONAL FUNCTIONS **************************/

  /**
  * [NOT MANDATORY FOR ERC1400 STANDARD]
  * @dev Definitely renounce the possibility to control tokens on behalf of tokenHolders.
  * Once set to false, '_isControllable' can never be set to 'true' again.
  */
  function renounceControl() external onlyOwner {
    _isControllable = false;
  } 

  /**
  * [NOT MANDATORY FOR ERC1400 STANDARD]
  * @dev Definitely renounce the possibility to issue new tokens.
  * Once set to false, '_isIssuable' can never be set to 'true' again.
  */
  function renounceIssuance() external onlyOwner {
    _isIssuable = false;
  }

  /**
  * [NOT MANDATORY FOR ERC1400 STANDARD]
  * @dev Set list of token controllers.
  * @param _operators Controller addresses.
  */
  function setControllers(address[] calldata _operators) external onlyOwner {
    _setControllers(_operators);
  }

  /**
  * [NOT MANDATORY FOR ERC1400 STANDARD]
  * @dev Set list of token partition controllers.
  * @param _partition Name of the partition.
  * @param _operators Controller addresses.
  */
  function setPartitionControllers(bytes32 _partition, address[] calldata _operators) external onlyOwner {
     _setPartitionControllers(_partition, _operators);
  }
  /**
   * [NOT MANDATORY FOR ERC1400Partition STANDARD]
   * @dev Get list of existing partitions.
   * @return Array of all exisiting partitions.
   */
  function totalPartitions() external view returns (bytes32[] memory) {
    return _totalPartitions;
  }
//     /**
//   * [NOT MANDATORY FOR ERC1400Partition STANDARD]
//   * @dev check Lockdata
//   * @param _partition  Name of the partition
//   * @return Lockdata
//   */
//   function getLockdata(bytes32 _partition) external view returns (uint256) {
//     return _PartitionwithLock[_partition];
//   }
}
