const TestApp = require('zos').TestApp;
const Tavern = artifacts.require('tavern/contracts/Tavern');
const BananoToken = artifacts.require('BananoToken');
const TestUtils = require('tavern/test/test-utils');

contract('BananoToken', function (accounts) {

  var app, tavernProxy, bananoTokenProxy;

  async function shouldCreateValidQuest(lat, lon, name, hint, maxWinners, metadata, txObject) {
    const initialQuestAmount = await tavernProxy.getQuestAmount(bananoTokenProxy.address),
          merkleTree = TestUtils.generateMerkleTree(lat,lon),
          merkleBody = TestUtils.encodeMerkleBody(merkleTree);

    const txResult = await tavernProxy.createQuest(
                            bananoTokenProxy.address,
                            name,
                            hint,
                            maxWinners,
                            '0x' + merkleTree.getRoot().toString('hex'),
                            merkleBody,
                            metadata,
                            txObject
                           );

    const finalQuestAmount = await tavernProxy.getQuestAmount(bananoTokenProxy.address);
    assert.equal(finalQuestAmount.toNumber(), initialQuestAmount.toNumber() + 1);
    return txResult;
  }

  before(async function () {
    tavernProxy = await Tavern.new({from: accounts[0]});
    app = await TestApp('zos.json', { from: accounts[0] });
    bananoTokenProxy = await app.createProxy(BananoToken, 'BananoToken', 'initialize', [accounts[0], tavernProxy.address]);
  });

  describe('#initialize', function() {
    it('should create a Tavern proxy with the right owner', async function () {
      const proxyOwner = await bananoTokenProxy.owner();
      assert.ok(bananoTokenProxy);
      assert.equal(proxyOwner, accounts[0]);
    });
  });

  describe('#validateQuest', function() {
    it('should mark the quest valid with the correct parameters', async function() {
      var questCreationTx = await shouldCreateValidQuest(
                                    40.6893,
                                    -74.0447,
                                    'This is a quest',
                                    'This is a hint',
                                    10,
                                    'some metadata',
                                    {from: accounts[0]}
                                  );

      var isQuestValid = await tavernProxy.getQuestValid(bananoTokenProxy.address, questCreationTx.logs[0].args._questIndex.toNumber());
      assert.ok(isQuestValid);
    });
  });

  // This test performs 3 steps: create's a new quest, does the client side work of stitching together the merkle tree,
  // and then submits the found proof to the contract.
  describe('#rewardCompletion', function() {
    it('should reward the user upon compltion of the quest', async function() {
      // First create the quest
      const questTxResult = await shouldCreateValidQuest(
                                  40.6893,
                                  -74.0447,
                                  'This is a quest',
                                  'This is a hint',
                                  10,
                                  'some metadata',
                                  {from: accounts[0]}
                                );

      // Have a player guess the answer
      const player = accounts[1],
            questIndex = questTxResult.logs[0].args._questIndex.toNumber(),
            merkleBody = await tavernProxy.getQuestMerkleBody(bananoTokenProxy.address, questIndex),
            playerSubmission = TestUtils.generatePlayerSubmission(40.6894,-74.0447, merkleBody);

      const submitProofTx = await tavernProxy.submitProof(
                                    bananoTokenProxy.address,
                                    questIndex,
                                    playerSubmission.proof,
                                    playerSubmission.answer,
                                    {
                                      from: player
                                    }
                                  );

      // Assert that player is winner
      const isWinner = await tavernProxy.isWinner(bananoTokenProxy.address, questIndex, player);
      const isClaimer = await tavernProxy.isClaimer(bananoTokenProxy.address, questIndex, player);
      assert.ok(isWinner);
      assert.ok(isClaimer);
    });
  });
});
