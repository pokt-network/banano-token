pragma solidity ^0.4.24;

import "openzeppelin-zos/contracts/ownership/Ownable.sol";
import "openzeppelin-zos/contracts/token/ERC721/MintableERC721Token.sol";
import "tavern/contracts/TavernQuestReward.sol";
import "tavern/contracts/Tavern.sol";

contract BananoToken is MintableERC721Token, TavernQuestReward {

    // State
    bool internal initialized;
    mapping(uint256 => string) internal tokenMetadata;
    mapping(uint256 => uint256) internal tokenQuestIndex;
    address internal tavernAddress;
    address[] internal tokenOwnersIndex;

    // Initializer
    function initialize(address _owner, address _tavernAddress) isInitializer("BananoToken", "0.0.2") public {
        require(!initialized);
        require(isValidAddress(_owner) == true);
        require(isValidAddress(_tavernAddress) == true);
        MintableERC721Token.initialize(_owner, "BananoToken", "BANANO");
        tavernAddress = _tavernAddress;
        initialized = true;
    }

    // Validates the parameters for a new quest
    function validateQuest(address _tavern, address _creator, string _name, string _hint, uint _maxWinners, bytes32 _merkleRoot, string _merkleBody, string _metadata, uint _prize) public returns (bool) {
        return isValidTavern(_tavern) && isValidAddress(_creator) && isValidString(_name) && isValidString(_hint) && _prize > 0 ? _maxWinners > 0 : true &&
                _merkleRoot.length == 32 && isValidString(_merkleBody) && isValidString(_metadata);
    }

    // Mint reward
    function rewardCompletion(address _tavern, address _winner, uint _questIndex) public returns (bool) {
        require(isValidAddress(_winner));
        require(isValidTavern(_tavern));
        bool result = false;

        Tavern tavernInterface = Tavern(_tavern);
        bool isWinner = tavernInterface.isWinner(this, _questIndex, _winner) == true;
        bool canClaim = tavernInterface.isClaimer(this, _questIndex, _winner) == false;
        if (isWinner && canClaim) {
            _mintQuestReward(_winner, _questIndex, tavernInterface.getQuestMetadata(this, _questIndex));
            result = true;
        }

        return result;
    }

    function _mintQuestReward(address _winner, uint256 _questIndex, string _questMetadata) internal {
        // Generate next token id
        uint256 nextTokenId = allTokens.length;

        // Mint the token
        super._mint(_winner, nextTokenId);

        // Add to owners index if not exists
        // We check for 1 because the _mint function will increase by 1 the count
        if (ownedTokensCount[_winner] == 1) {
            tokenOwnersIndex.push(_winner);
        }

        // Set token metadata
        _setTokenMetadata(nextTokenId, _questMetadata);

        // Set token quest index
        _setTokenQuestIndex(nextTokenId, _questIndex);
    }

    // Sets token metadata
    function _setTokenMetadata(uint256 _tokenId, string _metadata) internal {
      require(exists(_tokenId));
      tokenMetadata[_tokenId] = _metadata;
    }

    // Retrieves tokenMetadata
    function getTokenMedata(uint256 _tokenId) public view returns (string) {
      require(exists(_tokenId));
      return tokenMetadata[_tokenId];
    }

    // Sets token quest
    function _setTokenQuestIndex(uint256 _tokenId, uint256 _questIndex) internal {
      require(exists(_tokenId));
      tokenQuestIndex[_tokenId] = _questIndex;
    }

    // Retrieves quest
    function getTokenQuestIndex(uint256 _tokenId) public view returns (uint256) {
      require(exists(_tokenId));
      return tokenQuestIndex[_tokenId];
    }

    function isValidAddress(address _addressToCheck) internal pure returns (bool) {
        return _addressToCheck != address(0);
    }

    function isValidString(string _stringToCheck) internal pure returns (bool) {
        return bytes(_stringToCheck).length > 0;
    }

    function isValidTavern(address _addressToCheck) internal view returns (bool) {
        return _addressToCheck == tavernAddress;
    }

    function getOwnersCount() public view returns (uint256) {
        return tokenOwnersIndex.length;
    }

    function getOwnerTokenCountByIndex(uint256 _ownerIndex) public view returns (address, uint256) {
        address owner = tokenOwnersIndex[_ownerIndex];
        return(owner, ownedTokensCount[owner]);
    }
}
