pragma solidity ^0.4.18;

contract Greeter {
    mapping (uint8 => string) helloByLang;

    string goodbyeKorean = "잘가";
    string goodbyeEnglish = "Goodbye";
    
    enum Lang {Korean, English }

    constructor() public {
        helloByLang[uint8(Lang.Korean)] = "안녕";
        helloByLang[uint8(Lang.English)] = "hello";
    }

    function sayHello(uint8 lang) public view returns (string) {
        return helloByLang[lang];
    }
    
    function changeHello(uint8 lang,string _hello) public{
        helloByLang[lang] = _hello;
    }
}