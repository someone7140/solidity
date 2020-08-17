const GameFactory = artifacts.require('GameFactory');

module.exports = (deployer) => {
  deployer.deploy(GameFactory);
};
