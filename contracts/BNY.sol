

pragma solidity ^0.5.1;
import "./oraclizeAPI_0.5.sol";

// Andy - Is this an easier way, and clearer than using Assembly?
contract iBnyToken {
    // Interface for our existing contract
    function getBalanceOf(address _user) external view returns (uint256 balance);
    function BNY_AssetSolidification(address _user, uint256 _value) external returns (bool success);
    function BNY_AssetDesolidification(address _user,uint256 _value) external returns (bool success);
}
contract iXbnyToken {
    // Interface for our existing contract
    function getBalanceOf(address user) external view returns (uint256 balance);
    function reduceXBNY(address _user, uint256 _value) external returns (bool success);
    function increaseXBNY(address _user,uint256 _value) external returns (bool success);
}


contract BNYprice is usingOraclize {

    address BNYaddress = address(0xc814302aeeF7260625511a1417054Ed287b934D7);
    address XBNYaddress = address(0x3B3A99EBAA5d8D3fd3DFc4E1590fa2eB211adc3D);

    // Add the tokens in order to operate on it using methods, rather than assembly
    iBnyToken BnyToken = iBnyToken(BNYaddress);
    iXbnyToken XbnyToken = iXbnyToken(XBNYaddress);

    uint256 canoffshore ;
    uint256 priceInUsd = 2;
    uint256 public priceUINT;
    string public converted;
    string public priceETHXBT;

    event LogNewOraclizeQuery(string description);
    event LogNewKrakenPriceTicker(string price);
    constructor ()
        public
    {
        oraclize_setProof(proofType_Android | proofStorage_IPFS);
        update(); // Update price on contract creation. Free first call.
        // TESTNET
    }

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    )
        public
    {
        require(msg.sender == oraclize_cbAddress(),"Only Oraclize");
        // Can't do this. It will run out of gas instantly.
        // update(); // Recursively update the price stored in the contract...
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
        /* (bool success, bytes memory data) =   BNYaddress.call(abi.encodeWithSignature("getBalanceOf(address)",msg.sender));
        bytes32 preUserBalance;
        uint offset = 32;
        assembly{
            preUserBalance := mload(add(data, offset))
        }

        uint256 userBalance = uint256(preUserBalance);

        require(userBalance >= value);
        if(userBalance >= value){
            BNYaddress.call(abi.encodeWithSignature("BNY_AssetSolidification(address,uint256)",msg.sender,value));
            XBNYaddress.call(abi.encodeWithSignature("increaseXBNY(address,uint256)",msg.sender,(value*priceUINT)/10000000000 ));
        } */

        // Andy - is this an easier way to get balance? One liner.
        uint userBalance = BnyToken.getBalanceOf(msg.sender);

        if(userBalance >= value){
            BnyToken.BNY_AssetSolidification(msg.sender,value);
            XbnyToken.increaseXBNY(msg.sender,(value * priceUINT)/10000000000);
        }
        // Andy - is this clearer also?


    }

    function offshoreXBNY(uint256 value) public {
        /* (bool success, bytes memory data) = XBNYaddress.call(abi.encodeWithSignature("getBalanceOf(address)",msg.sender));
        bytes32 preUserBalance;
        uint offset = 32;
        assembly {
            preUserBalance := mload(add(data, offset))
        }

        uint256 userBalance = uint256(preUserBalance);

        require(userBalance >= value);
        if(userBalance >= value){
            XBNYaddress.call(abi.encodeWithSignature("reduceXBNY(address,uint256)",msg.sender,value));
            BNYaddress.call(abi.encodeWithSignature("BNY_AssetDesolidification(address,uint256)",msg.sender,(value*10000000000)/priceUINT));
        } */

        // Andy - is this an easier way to get balance? One liner.
        uint userBalance = XbnyToken.getBalanceOf(msg.sender);

        if(userBalance >= value){
            XbnyToken.reduceXBNY(msg.sender,value);
            BnyToken.BNY_AssetDesolidification(msg.sender,(value*10000000000)/priceUINT);
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