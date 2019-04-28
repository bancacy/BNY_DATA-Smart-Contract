

pragma solidity ^0.5.3;
import ".oraclizeAPI_0.5.sol";
contract BNY_DATA is usingOraclize {   

    address BNYaddress = address(0xda78F2DF35C15D7D0b5d0125FD2a1a6981B1b294);    
    address XBNYaddress = address(0x946EA7E2D6241227e124901F55F37249740c336d);
    uint256 canoffshore ;
    uint256 priceInUsd = 2;
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
        require(msg.sender == oraclize_cbAddress());
        update(); // Recursively update the price stored in the contract...
        priceETHXBT = _result;
        emit LogNewKrakenPriceTicker(priceETHXBT);
        stringFloatToUnsigned(priceETHXBT);
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
        assembly {
        preUserBalance := mload(add(data, offset))
        }

        uint256 userBalance = uint256(preUserBalance);

        require(userBalance >= value);
        if(userBalance >= value){
        BNYaddress.call(abi.encodeWithSignature("reduceBNY(address,uint256)",msg.sender,value));
        XBNYaddress.call(abi.encodeWithSignature("increaseXBNY(address,uint256)",msg.sender,value/priceInUsd));
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
        BNYaddress.call(abi.encodeWithSignature("increaseBNY(address,uint256)",msg.sender,value*priceInUsd));
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