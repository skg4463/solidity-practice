pragma solidity ^0.4.18;

contract SecureGeneralWalletCompatibleToken {
    /* Constructor */
    string public name;
    string public symbol;
    uint8 public decimals;
    
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address _from, address _to, uint _value);
    
    constructor(string _name, string _symbol, uint8 _decimalUnits, uint256 initialSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimalUnits;
        balanceOf[msg.sender] = initialSupply;
    }
    
    function transfer(address _to, uint256 _value) public {
        require(_value <= balanceOf[msg.sender]);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
    
    
}