

pragma solidity ^0.5.1;
import "./oraclizeAPI_0.5.sol";
contract BNYprice is usingOraclize {

    address BNYaddress = address(0xBA0b88792D94811ED7d550fCBC8857Be807A12D1);
    address XBNYaddress = address(0x7AE9Bf69424d300a21DeDf8300C07D4f8F9143b6);
    uint256 canoffshore ;
    uint256 priceInUsd = 2;
    uint256 public priceUINT ;
     string public converted;
    string public priceETHXBT;


    event LogNewOraclizeQuery(string description);
    event LogNewKrakenPriceTicker(string price);
     constructor()
        public
    {
        oraclize_setProof(proofType_Android | proofStorage_IPFS);
        update(); // Update price on contract creation...
    }

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    )
        public
    {
        require(msg.sender == oraclize_cbAddress(),"Only Oraclize");
        update(); // Recursively update the price stored in the contract...
        priceETHXBT = _result;
        emit LogNewKrakenPriceTicker(priceETHXBT);
        stringFloatToUnsigned(priceETHXBT);
        priceUINT = safeParseInt(priceETHXBT, 10);
        
    }

    function update()
        public
        payable
    {
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee!");
        } else {
            emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer...");
            oraclize_query(60, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHXBT).result.XETHXXBT.c.0");
        }
        
    }
   
    function offshoreBNY(uint256 value) public {
        
        (bool success, bytes memory data) =   BNYaddress.call(abi.encodeWithSignature("GetbalanceOf(address)",msg.sender));
        bytes32 preUserBalance;
        uint offset = 32;
        assembly{
        preUserBalance := mload(add(data, offset))
        }

        uint256 userBalance = uint256(preUserBalance);

        require(userBalance >= value);
        if(userBalance >= value){
        
        BNYaddress.call(abi.encodeWithSignature("reduceBNY(address,uint256)",msg.sender,value));
        XBNYaddress.call(abi.encodeWithSignature("increaseXBNY(address,uint256)",msg.sender,(value*priceUINT)/10000000000 ));
        }
    }
    
    function offshoreXBNY(uint256 value) public {
        
        (bool success, bytes memory data) =   XBNYaddress.call(abi.encodeWithSignature("GetbalanceOf(address)",msg.sender));
        bytes32 preUserBalance;
        uint offset = 32;
        assembly {
        preUserBalance := mload(add(data, offset))
        }

        uint256 userBalance = uint256(preUserBalance);
        
        require(userBalance >= value);
        if(userBalance >= value){
        XBNYaddress.call(abi.encodeWithSignature("reduceXBNY(address,uint256)",msg.sender,value));
        BNYaddress.call(abi.encodeWithSignature("increaseBNY(address,uint256)",msg.sender,(value*10000000000)/priceUINT));
        }
    }
    
    function stringFloatToUnsigned(string memory _s)public payable {
        uint stringLength = bytes(_s).length;
        bytes memory _new_s = new bytes(stringLength);
        
        uint k = 0;

        for (uint i = 0; i < bytes(_s).length; i++) {
            if (bytes(_s)[i] == '.') { continue; }

            _new_s[k] = bytes(_s)[i];
            k++;
        }

        converted = string(_new_s);
    }

    
}