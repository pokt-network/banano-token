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
    address internal tavern;

    // Initializer
    function initialize(address _owner, address _tavern) isInitializer("BananoToken", "0.0.1") public {
        require(!initialized);
        require(isValidAddress(_owner) == true);
        require(isValidAddress(_tavern) == true);
        MintableERC721Token.initialize(_owner, "BananoToken", "BANANO");
        tavern = _tavern;
        initialized = true;
    }

    // Validates the parameters for a new quest
    function validateQuest(address _tavern, address _creator, string _name, string _hint, uint _maxWinners, bytes32 _merkleRoot, string _merkleBody, string _metadata, uint _prize) public returns (bool) {
        return true;
    }

    // Mint reward
    function rewardCompletion(address _tavern, address _winner, uint _questIndex) public returns (bool) {
        return true;
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

    // Used for enumeration
    function tokenAmountOfOwner(address _owner) public view returns (uint256) {
        return ownedTokens[_owner].length;
    }

    function isValidAddress(address _addressToCheck) internal view returns (bool) {
        return _addressToCheck != address(0);
    }
}
