// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";
import "./Marketplace.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Game is Ownable {
    Token token;
    Marketplace marketplace;

    uint256[] public weapons = [2, 3, 4, 5, 6];
    uint256 public SOLDIER = 0;
    uint256 public GOLD = 1;
    uint256 public PISTOL = 2;
    uint256 public RIFLE = 3;
    uint256 public SNIPER = 4;
    uint256 public ARMOR = 5;
    uint256 public MACHINEGUN = 6;
    uint256 public playerCount;
    address public loser;
    address public winner;
    address public mvp1;
    address public mvp2;
    address public mvp3;
    uint256[] public totalbalances;
    uint256 pistolBalance = token.balanceOf(msg.sender, PISTOL);
    uint256 rifleBalance = token.balanceOf(msg.sender, RIFLE);
    uint256 sniperBalance = token.balanceOf(msg.sender, SNIPER);
    uint256 armorBalance = token.balanceOf(msg.sender, ARMOR);
    uint256 machineGunBalance = token.balanceOf(msg.sender, MACHINEGUN);
    uint256[] weaponBalances = [pistolBalance, rifleBalance, sniperBalance, armorBalance, machineGunBalance];

    struct weaponsWithBalances {
        address owner;
        uint[] ownerWeapons;
        uint[] ownerWeaponBalances;
    }
    mapping(address => bool) public registered;
    mapping(address => bool) public tutorialCompleted;
    mapping(address => bool) public sideChallenge1Completed;
    mapping(address => mapping(uint256 => uint256)) public waitingList;
    mapping(address => uint256) public soldiersHeld;
    mapping(address => weaponsWithBalances) public allWeaponsWithBalances; 
    mapping(address => mapping(uint256 => uint256)) public weaponWithBalances;
    
    constructor(address _token) {
        token = Token(_token);
    }

    //registering will mint 1 soldier and 1 armor
    function register() external {
        require(!registered[msg.sender], "user is already registered"); //require user is not already registered
        token.mint(msg.sender, SOLDIER, 1, "");
        token.mint(msg.sender, ARMOR, 1, "");
        registered[msg.sender] = true;
    }

    //complete tutorial to unlock pistol
    function tutorial() external {
        require(!tutorialCompleted[msg.sender], "user already completed tutorial");
        token.mint(msg.sender, PISTOL, 1, "");
        tutorialCompleted[msg.sender] = true;
    }

    //complete side challenge 1 to unlock rifle 
    function sideChallenge1() external {
        require(!sideChallenge1Completed[msg.sender], "user already completed side challenge 1");
        token.mint(msg.sender, RIFLE, 1, "");
        sideChallenge1Completed[msg.sender] = true;
    }

    //function to play as team owner, meaning one is using one's soldiers and weapons to lead the game
    function playAsOwner() external {
        uint256 soldierBalance = token.balanceOf(msg.sender, 0); // owner must have at least 3 soldiers
        require(soldierBalance >= 3);
        token.safeBatchTransferFrom(msg.sender, address(this), weapons, weaponBalances, "");
        weaponsWithBalances storage _weaponsWithBalances = allWeaponsWithBalances[msg.sender];
        _weaponsWithBalances.owner = msg.sender;
        _weaponsWithBalances.ownerWeapons = weapons;
        _weaponsWithBalances.ownerWeaponBalances = weaponBalances;
        token.safeTransferFrom(msg.sender, address(this), 0, soldierBalance, ""); //Transfer owners soldiers into game contract to hold during game
        soldiersHeld[msg.sender] = soldierBalance;
    }
    //function to play as soldier- one is using owner's soldier and weapons
    function playAsSoldier() external {
        uint256 goldBalance = token.balanceOf(msg.sender, 1);
        require(goldBalance >= 50, "Must have at least 50 gold to play as soldier");
        token.safeTransferFrom(msg.sender, address(this), 1, 50, ""); //one must deposit 50 gold coins which will be returned at the end of the game; this ensures players do not quit early.
    }
    //function to claim gold if one does not have enough gold to play, this will force a commercial which will earn revenue for the game.
    function iAmbroke () external {
        uint256 goldBalance = token.balanceOf(msg.sender, 1);
        require(goldBalance < 50, "Must have at less than 50 gold to be broke");
        uint256 goldNeeded = 50 - goldBalance;
        token.mint(msg.sender, GOLD, goldNeeded, "");
    }
    // upon victory, winning player gets to decide whether to capture the enemy's soldiers
    // or execute them. If soldiers are captured they will be sent to the winner's baracks for 1 week of recovery before they can be used, however
    // the enemy will get to keep their weapons. If the winner decides to execute the enemy team, the enemy soldiers will be burned,
    // and the winner will be able to immediately collect all weapons.

    function victoryCapture() external {
        require(msg.sender == winner); //only winner can call function
        waitingList[msg.sender][SOLDIER] = block.timestamp + 3 days;
    }
    

    function claimVictory() external {
        require(msg.sender == winner);
        require(
            block.timestamp >= waitingList[msg.sender][SOLDIER],
            "Timelock"
        );
        uint256 winnerSoldiers = soldiersHeld[msg.sender];
        uint256 loserSoldiers = soldiersHeld[loser];
        token.safeTransferFrom(address(this), winner, 0, winnerSoldiers, ""); //transfer all soldiers from loser to winner
        token.safeTransferFrom(address(this), winner, 0, loserSoldiers, "");
        soldiersHeld[msg.sender] = 0;
        soldiersHeld[loser] = 0;
    }

    function victoryExecute() external {
        require(msg.sender == winner); //only winner can call function
        uint256 soldierBalance = token.balanceOf(loser, SOLDIER); //total amount of soldiers loser has
        token.burn(loser, SOLDIER, soldierBalance); // burn all the soldiers loser has
        token.safeBatchTransferFrom(loser, winner, weapons, totalbalances, ""); //transfer all weapons and weapon balances from loser to winner
    }

    // upon winning, winner will collect a reward (gold). The top 3 performing players will also receive gold.
    // this will incentivize players to take the game seriously.
    function receiveWinnings() external {
        require(msg.sender == winner); //only winner may claim winnings
        if (playerCount >= 5) {
            token.mint(winner, 1, 200, "");
            token.mint(mvp1, 1, 200, "");
            token.mint(mvp2, 1, 200, "");
            token.mint(mvp3, 1, 200, "");
            // if player count is less than 5 players, // reward size decreases
        } else {
            token.mint(winner, 1, 200, "");
            token.mint(mvp1, 1, 75, "");
            token.mint(mvp2, 1, 75, "");
            token.mint(mvp3, 1, 75, "");
        }
    }
    // After game, all players besides winner may retrieve gold deposited at beginning of game.
    function retrieveGold() external {
        require(msg.sender != winner);
        token.safeTransferFrom(address(this), msg.sender, GOLD, 50, "");
    }

    //check inventory balance of any item
    function checkBalance(uint256 id) external view returns (uint) {
       return token.balanceOf(msg.sender, id);
    }

    //player can gift gold to another player
    function giveGold(address player, uint256 amount) external {
        require(token.balanceOf(msg.sender, 1) >= amount); //make sure player has enough gold to send
        token.safeTransferFrom(msg.sender, player, 1, amount, "");
    }
    function setMarketplaceContract(address _marketplace) external onlyOwner {
        marketplace = Marketplace(_marketplace);
    }
    function setWinner(address _winner) external onlyOwner {
        winner = _winner;
    }
    function setLoser(address _loser) external onlyOwner {
        loser = _loser;
    }
    function setMvp1(address _mvp1) external onlyOwner {
        mvp1 = _mvp1;
    }
    function setMvp2(address _mvp2) external onlyOwner {
        mvp2 = _mvp2;
    }
    function setMvp3(address _mvp3) external onlyOwner {
        mvp3 = _mvp3;
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return
            bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}
