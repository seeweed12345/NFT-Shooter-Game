const Token = artifacts.require("Token");
const Game = artifacts.require("Game");
const Marketplace = artifacts.require("Marketplace");

module.exports = async function (deployer) {
  await deployer.deploy(Token);
  await deployer.deploy(Game, Token.address);
  await deployer.deploy(Marketplace, Marketplace.address);
  const token = await Token.deployed();
  const game = await Game.deployed();
  const marketplace = await Marketplace.deployed();
  await game.register();
  const minterRole = await token.MINTER_ROLE();
  await token.grantRole(minterRole, game.address);
  const isRegistered = await game.registered(accounts(1));
};
