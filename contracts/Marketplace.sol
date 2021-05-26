// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";
import "./Game.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    Token token;
    Game game;

    constructor(address _token) {
        token = Token(_token);
    }

    // prices by id
    mapping(uint256 => uint256) public prices;

    function buyItem(uint256 id, uint256 amount) external {
        require(token.balanceOf(address(this), id) >= amount); //require market to have enough stock of chosen item
        require(token.balanceOf(address(this), 1) > 50); //must have at least 51 gold to purchase anything, this prevents players from abusing iAmBroke function
        uint256 _price = prices[id];
        uint256 totalPrice = _price * amount;
        require(token.balanceOf(msg.sender, 1) >= totalPrice); //require buyer to have enough gold to purchase item
        token.safeTransferFrom(msg.sender, address(this), 1, totalPrice, ""); // gold gets sent to marketplace
        token.safeTransferFrom(address(this), msg.sender, id, amount, ""); // item gets sent to buyer
    }
    function sellItem(uint id, uint amount) external {
        token.safeTransferFrom(msg.sender, address(this), id, amount, "");
        uint256 _price = prices[id];
        uint goldAmount = _price * amount;
        token.mint(msg.sender, 1, goldAmount, "");
    }

    function setPrice(uint256 id, uint256 price) external onlyOwner {
        prices[id] = price;
    }
    function setGameContract(address _game) external onlyOwner {
        game = Game(_game);
    }
    function mintInitialTokens() external onlyOwner {
     //snipers, armor, and machine guns are minted and available for sale upon contract launch.
        token.mint(address(this), 4, 1500, "");
        token.mint(address(this), 5, 100000000000000, "");
        token.mint(address(this), 6, 800, "");
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
