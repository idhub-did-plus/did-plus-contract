pragma solidity^0.5.0;

interface IERC1400 {

  // Document Management
  function getDocument(bytes32 _name) external view returns (string memory, bytes32);   //ok
  function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external; //ok

  // Token Information
  function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns (uint256); //ok
  function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory); //ok

  // Transfers
  //function transferWithData(address _to, uint256 _value, bytes _data) external;  //not need
  //function transferFromWithData(address _from, address _to, uint256 _value, bytes _data) external; //not need

  // Partition Token Transfers
  function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes calldata _data) external returns (bytes32); //ok
  function operatorTransferByPartition(bytes32 _partition, address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata  _operatorData) external returns (bytes32); //ok

  // Controller Operation
  function isControllable() external view returns (bool); //ok
  function controllerTransfer(bytes32 _partition,address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external; //ok
  function controllerRedeem(bytes32 _partition,address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;//ok
 
  // Operator Management
  function authorizeOperator(address _operator) external;  //ok
  function revokeOperator(address _operator) external; //ok
  function authorizeOperatorByPartition(bytes32 _partition, address _operator) external;//ok
  function revokeOperatorByPartition(bytes32 _partition, address _operator) external; //ok

  // Operator Information
  function isOperator(address _operator, address _tokenHolder) external view returns (bool);//ok
  function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool); //ok

  // Token Issuance
  function isIssuable() external view returns (bool); //ok
  //function issue(address _tokenHolder, uint256 _value, bytes _data) external; //not need
  function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data,uint _Day) external; //ok

  // Token Redemption
  //function redeem(uint256 _value, bytes _data) external;//not need
  //function redeemFrom(address _tokenHolder, uint256 _value, bytes _data) external;//not need
  function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata  _data) external; //ok
  function operatorRedeemByPartition(bytes32 _partition, address _tokenHolder, uint256 _value,bytes calldata _data,bytes calldata _operatorData) external; //ok

  // Transfer Validity
  //function canTransfer(address _to, uint256 _value, bytes _data) external view returns (byte, bytes32);//not need
  //function canTransferFrom(address _from, address _to, uint256 _value, bytes _data) external view returns (byte, bytes32);//not need
  function canTransferByPartition(bytes32 _partition,address _from, address _to, uint256 _value, bytes calldata _data) external view returns (byte, bytes32, bytes32);  //ok  

  // Controller Events
  event ControllerTransfer(                                                  //ok
      address _controller,
      address indexed _from,
      address indexed _to,
      uint256 _value,
      bytes _data,
      bytes _operatorData
  );

  event ControllerRedemption(                                                 //ok
      address _controller,
      address indexed _tokenHolder,
      uint256 _value,
      bytes _data,
      bytes _operatorData
  );

  // Document Events
  event Document(bytes32 indexed _name, string _uri, bytes32 _documentHash);  //ok

  // Transfer Events
  event TransferByPartition(                                                  //ok
      bytes32 indexed _fromPartition,
      address _operator,
      address indexed _from,
      address indexed _to,
      uint256 _value,
      bytes _data,
      bytes _operatorData
  );

  event ChangedPartition(                                                     //ok
      bytes32 indexed _fromPartition,
      bytes32 indexed _toPartition,
      uint256 _value
  );

//   // Operator Events
  event AuthorizedOperator(address indexed _operator, address indexed _tokenHolder);  //ok
  event RevokedOperator(address indexed _operator, address indexed _tokenHolder);     //ok
  event AuthorizedOperatorByPartition(bytes32 indexed _partition, address indexed _operator, address indexed _tokenHolder);//ok
  event RevokedOperatorByPartition(bytes32 indexed _partition, address indexed _operator, address indexed _tokenHolder);//ok

//   // Issuance / Redemption Events
  event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);  //ok
  event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data); //ok
  event IssuedByPartition(bytes32 indexed _partition, address indexed _operator, address indexed _to, uint256 _value, bytes _data, bytes _operatorData); //ok
  event RedeemedByPartition(bytes32 indexed _partition, address indexed _operator, address indexed _from, uint256 _value, bytes _operatorData);//ok


}
