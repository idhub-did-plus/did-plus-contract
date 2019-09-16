pragma solidity^0.5.0;


contract whitelist {
    

    address[] PersonalAdd;
    address owner;
       
    
    event AddP(address Addr);
    event RevokeP(address Addr);
    
    constructor()public{
            owner = msg.sender;
        }
        
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }   
    
    uint time = 1 days;
    
 /**
  * @dev Add address to the whitelist
  * @param _personal is address about KYC accredited.
  */
    
    function AddPersonal(address _personal) public onlyOwner {
        
        PersonalAdd.push(_personal);
        emit AddP(_personal);
        
    }
    
 /**
  * @dev revoke address to the whitelist
  * @param _personal is address.
  */ 
  
    function RevokePersonal(address _personal) public onlyOwner {
        
        for (uint i = 0;i<PersonalAdd.length;i++){
            if (_personal == PersonalAdd[i]){
                delete PersonalAdd[i];
            }
        }
        emit RevokeP(_personal);
        
    }
    
 /**
  * @dev find address to the whitelist
  * @param _personal is address.
  */ 
  
    function FindPersonal(address _personal) public view returns(bool) {
        
        for (uint i = 0;i<PersonalAdd.length;i++){
            if (_personal == PersonalAdd[i]){
                return true;
            }
        }
        return false;
    }
//  /**
//   * @dev Computational Lock
//   * @param _data is Lockdata.
//   */ 
  
//     function getdata(uint _data) public returns(uint256 Lockdata){
//         uint Lockwithdata = now + time*_data;
//         Lockdata = uint256(Lockwithdata);
//         return Lockdata;
//     }
}
