const Game = artifacts.require("Game");
const Token = artifacts.require("Token");
const Marketplace = artifacts.require("Marketplace");

const {
  expectRevert,
  expectEvent,
  time,
} = require("@openzeppelin/test-helpers");
const { assertion } = require("@openzeppelin/test-helpers/src/expectRevert");

contract("Game", (accounts) => {
    let token;
    let game;
    let marketplace;

    before(async function () {
        token = await Token.new();
        game = await Game.new(token.address);
        marketplace = await Marketplace.new(token.address);
        await game.setMarketplaceContract(marketplace.address);
        await marketplace.setGameContract(game.address);
        //grant minter role to game address
        const minterRole = await token.MINTER_ROLE();
        await token.grantRole(minterRole, game.address);
        await token.grantRole(minterRole, marketplace.address);
        await marketplace.mintInitialTokens();   
    });
    it("should be able to register a player", async function() {
        await game.register({from: accounts[1]})
    });
    it("An already registered player can not register again", async function() {
        await expectRevert(game.register({from: accounts[1]}), "user is already registered");
    });
    it("The player receives 1 soldier after registering", async function() {
        await game.register({from: accounts[2]});
        const soldierBalance = await token.balanceOf(accounts[2], 0);
        assert.equal(soldierBalance, 1);
    });
    it("The player receives 1 armor after registering", async function() {
        const armorBalance = await token.balanceOf(accounts[2], 5);
        assert.equal(armorBalance, 1);
    });
    it("should be able to complete tutorial", async function() {
        await game.tutorial({from: accounts[1]});
    });
    it("The player receives 1 pistol after completing tutorial", async function() {
        const pistolBalance = await token.balanceOf(accounts[1], 2);
        assert.equal(pistolBalance, 1);
    });
    it("A player that completed the tutorial cannot redo the tutorial", async function() {
        await expectRevert(game.tutorial({from: accounts[1]}), "user already completed tutorial");
    });
    it("should be able to complete sideChallenge1", async function() {
        await game.sideChallenge1({from: accounts[1]});
    });
    it("The player receives 1 rifle after completing sideChallenge1", async function() {
        const rifleBalance = await token.balanceOf(accounts[1], 3);
        assert.equal(rifleBalance, 1);
    });
    it("A player that completed the side challenge 1 cannot redo side challenge 1", async function() {
        await expectRevert(game.sideChallenge1({from: accounts[1]}), "user already completed side challenge 1");
    });
    it("Player can check the inventory stock of any item", async function() {
        const rifleBalance = await game.checkBalance(3, {from: accounts[1]});
        assert.equal(rifleBalance, 1);
    });
    it("snipers, armor, and machine guns are minted and available for sale upon contract launch", async function() {
        const sniperBalance = await token.balanceOf(marketplace.address, 4);
        assert.equal(Number(sniperBalance), 1500);
        const armorBalance = await token.balanceOf(marketplace.address, 5);
        assert.equal(Number(armorBalance), 1e14);
        const machineGunBalance = await token.balanceOf(marketplace.address, 6);
        assert.equal(Number(machineGunBalance), 800);
    });
    it("owner can set price of an item", async function() {
        await marketplace.setPrice(3, 25);
        const riflePrice = await marketplace.prices(3);
        assert.equal(riflePrice, 25);
    });
    it("Winner is determined", async function() {
        await game.setWinner(accounts[8]);
        const winner = await game.winner();
        assert.equal(winner, accounts[8]);
    });
    it("Loser is determined", async function() {
        await game.setLoser(accounts[15]);
        const loser = await game.loser();
        assert.equal(loser, accounts[15]);
    });
    it("Mvp1 is determined", async function() {
        await game.setMvp1(accounts[10]);
        const mvp1 = await game.mvp1();
        assert.equal(mvp1, accounts[10]);
    });
    it("Mvp2 is determined", async function() {
        await game.setMvp2(accounts[11]);
        const mvp2 = await game.mvp2();
        assert.equal(mvp2, accounts[11]);
    });
    it("Mvp3 is determined", async function() {
        await game.setMvp3(accounts[12]);
        const mvp3 = await game.mvp3();
        assert.equal(mvp3, accounts[12]);
    });
    it("Owner can transfer soldiers into game contract when initiating game", async function() {
        await token.mint(accounts[15], 1, 500, "0x");
        await token.mint(accounts[15], 0, 10, "0x");
        await token.mint(accounts[8], 1, 500, "0x");
        await token.mint(accounts[8], 0, 10, "0x");
        await token.setApprovalForAll(game.address, true, {from: accounts[15]});
        await token.setApprovalForAll(game.address, true, {from: accounts[8]});
        await game.playAsOwner({from: accounts[8]});
        await game.playAsOwner({from: accounts[15]});
        const soldiersHeld = await game.soldiersHeld(accounts[15]);
        console.log(Number(soldiersHeld));
    });
    it("Winner can capture enemy soldiers", async function() {
        await token.setApprovalForAll(game.address, true, {from: accounts[8]});
        await game.victoryCapture({from: accounts[8]});
        await time.advanceBlock();
        await time.increase(time.duration.days(3));
        await game.claimVictory({from: accounts[8]});
        const soldierBalanceAfterGame = await token.balanceOf(accounts[8], 0);
        console.log(Number(soldierBalanceAfterGame));
    });
});
