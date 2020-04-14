pragma solidity ^0.5.0;

contract hermaRaccoon  {

    //master권한 address
    address public masterAddress;
    //채널 내 총 raccoon의 개체 수 
    uint256 public numberOfRaccoons;

    //현재 임신중이 raccoon의 개체 수
    uint256 public pregnantRaccoons;

    //genesisRaccoon 개체수제한
    uint256 public constant limit = 10;
    //genesisRaccoon 현개체
    uint256 public genesisCreated;

    //Raccoon의 구성요소
    struct Raccoon {
        uint256 genes; //유전자
        uint64 birthTime; //태어난 block.timestamp
        uint32 XYId; //부 id
        uint32 XXId; //모 id
        uint16 generation; //세대번호
        uint32 pregnantWithId; // 임신중이라면 부의 id
        uint64 cooldownEndBlock; //최근에 임신 후 쿨타임
        uint64 readyBirthTime; //임신 중이 아니라면 0, 임신 중이면 출산block
    }
    //master Raccoon 저장배열
    Raccoon[] Raccoons;
    //raccoonId => OwnerAddress
    mapping (uint256 => address) public RaccoonOwnerIndex;

    //master 권한 업데이트 이벤트
    event UpdateMaster(address previous, address newnow);
    //raccoon 분양 이벤트
    event Transfer(address from, address to, uint256 raccoonId);
    //raccoon 출산 이벤트
    event Birth(address owner, uint256 raccoonId, uint256 XYID, uint256 XXID, uint16 generation);
    //raccoon 임신 이벤트, XXId의 raccoon이 임신
    event Pregnant(address owner, uint256 XYId, uint256 XXId);


    function axe() public view returns (uint) {
        return Raccoons.length;
    }
    function axe2(uint _index) public view returns (uint bbool, uint index) {
        if(RaccoonOwnerIndex[_index] == msg.sender){
            bbool = 1;
            index = _index;
        }
        else{
            bbool = 0;
            index = _index;
        }
    }
/*   centralize로 삭제
    //master권한 확인 모디파이어
    modifier onlyMaster(){
        require(msg.sender == masterAddress);
        _;
    }
*/
/*
    //newMaster에 권한이양
    function setMaster(address _newMaster) public onlyMaster {
        require(_newMaster != address(0));
        address previous = masterAddress;

        masterAddress = _newMaster;
        emit UpdateMaster(previous, _newMaster);
    }
*/
    constructor() public {
        //masterAddress = msg.sender;
        _createRaccoon(0, 0, 0, uint16(-1), address(0));
    }

    //raccoon 분양
    function _RaccoonTransfer(address _from, address _to, uint256 _tokenId) internal {
        RaccoonOwnerIndex[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    //raccoon 생성
    function _createRaccoon(
        uint256 _genes,
        uint256 _XYId,
        uint256 _XXId,
        uint16 _generation,
        address _owner
    ) internal returns (uint){
        Raccoon memory _raccoon = Raccoon({
            genes : _genes,
            birthTime : uint64(block.timestamp),
            XYId : uint32(_XYId),
            XXId : uint32(_XXId),
            generation : uint16(_generation),
            pregnantWithId : 0,
            cooldownEndBlock : 0,
            readyBirthTime : 0
        });

        uint256 newRaccoonId = Raccoons.push(_raccoon) - 1;

        emit Birth (
            _owner, 
            newRaccoonId, 
            uint256(_raccoon.XYId), 
            uint256(_raccoon.XXId),
            _raccoon.generation
        );

        numberOfRaccoons++;
        //출산후 인자로 주어진 _owner에게 소유권 부여
        _RaccoonTransfer(address(0), _owner, newRaccoonId);

        return newRaccoonId;
    }

    //유전자결합
    function mixGenes(Raccoon memory XY, Raccoon memory XX) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(XY.genes, XX.genes)));
    }


    //RacoonOwnership
    function _own(address _requester, uint256 _token) internal view returns (bool) {
        return RaccoonOwnerIndex[_token] == _requester;
    }

    //raccoonBreeding
    

    function _isReadyToBreed(Raccoon memory _rac) internal view returns (bool) {
        return ((_rac.pregnantWithId == 0) && _rac.cooldownEndBlock <= uint64(block.number));
    }


    //would u fuck me?              you            me
    function breedRequest(uint256 _XYId, uint256 _XXId) external {
        Raccoon storage XY = Raccoons[_XYId];
        Raccoon storage XX = Raccoons[_XXId];

        require(_own(msg.sender, _XXId));
        require(_isReadyToBreed(XY));
        require(_isReadyToBreed(XX));
        require(XX.birthTime > 2);

        _breedWith(_XYId, _XXId);
    }   

    //do sex 한방에 임신
    function _breedWith(uint256 _XYId, uint256 _XXId) internal {
        //Raccoon storage XY = Raccoons[_XYId];
        Raccoon storage XX = Raccoons[_XXId];

        XX.pregnantWithId = uint32(_XYId);
        
        pregnantRaccoons++;
        //임신,교배 쿨타임 : 5blocks
        XX.cooldownEndBlock = uint64(block.number) + 5;
        XX.readyBirthTime = uint64(block.number) + 2;
        emit Pregnant(RaccoonOwnerIndex[_XXId], _XXId, _XYId);
    }

    function _isReadyToGiveBirth(Raccoon memory _XX) private view returns (bool) {
        return (_XX.pregnantWithId != 0) && (_XX.readyBirthTime < uint64(block.number));
    }

    function giveBirth(uint256 _XXId) external returns (uint256) {
        Raccoon storage XX = Raccoons[_XXId];
        //출산준비 확인
        require(_isReadyToGiveBirth(XX));

        uint256 XYId = XX.pregnantWithId;
        Raccoon storage XY = Raccoons[XYId];
        //자식의 유전자 계산
        uint256 childGene = mixGenes(XX, XY);
        //자식의 세대 부여
        uint16 parentGen = XX.generation;
        if(XX.generation < XY.generation) {
            parentGen = XY.generation;
        }
        //자식의 주인은 출산한 XX의 owner로
        address owner = RaccoonOwnerIndex[_XXId];
        //생성된 정보로 자식라쿤 생성
        uint256 childId = _createRaccoon(childGene, XX.pregnantWithId, _XXId, parentGen, owner);
        //임신정보 삭제
        delete XX.pregnantWithId;
        //임신한 라쿤수 감소
        pregnantRaccoons--;

        return childId;
    }



    //genesisRaccoon 
    function genesisRaccoon(uint256 _gene) external {
        address raccoonOwner = msg.sender;
        require(genesisCreated <= limit, "genesisCreated Raccoon is full!");
        
        genesisCreated++;
        _createRaccoon(_gene, 0, 0, 0, raccoonOwner);
    }

    function getGenesisRacNumber() public view returns (uint) {
        return genesisCreated;
    }

    
    function getRacNumber() public view returns (uint) {
        return numberOfRaccoons;
    }
    
    function getRaccoon(uint256 _id) external view returns (
        uint256 genes,
        uint64 birthTime, 
        uint32 XYId,
        uint32 XXId, 
        uint16 generation,
        uint32 pregnantWithId,
        uint64 cooldownEndBlock
    ){
        Raccoon storage rac = Raccoons[_id];

        genes = rac.genes;
        birthTime = rac.birthTime;
        XYId = rac.XYId;
        XXId = rac.XXId;
        generation = rac.generation;
        pregnantWithId = rac.pregnantWithId;
        cooldownEndBlock = rac.cooldownEndBlock;
    }

}