// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";

contract RandomGameWinner is VRFConsumerBase, Ownable {
    IERC20 public rewardToken;
    uint256 public totalPrizePool;
    uint256 public totalEntries;
    uint256 public winners;

    address[] public registeredUsers;

    mapping(address => bool) public isUserRegisterd;

    //Chainlink variables
    // The amount of LINK to send with the request
    uint256 public fee;

    // ID of public key against which randomness is generated
    bytes32 public keyHash;

    struct Player {
        address playerAddy;
        uint256 entries;
    }

    // Address of the players
    Player[] public players;

    // Mapping to track participant index
    mapping(address => uint256) public playerIndex;

    //Max number of players in one game
    uint256 maxEntries;

    // Variable to indicate if the game has started or not
    bool public gameStarted;

    // the fees for entering the game
    uint256 entryFee;

    // current game id
    uint256 public gameId;

    bool public prizeDistributionStarted = false;

    // emitted when the game starts
    event GameStarted(uint256 gameId, uint256 maxEntries, uint256 entryFee);

    // emitted when someone joins a game
    event PlayerJoined(uint256 gameId, address player);

    // emitted when the game ends
    event GameEnded(uint256 gameId, address winner, bytes32 requestId);

    event EntriesAdded(address participant, uint256 entries);

    event UserRegistration(address user);

    /**
     * constructor inherits a VRFConsumerBase and initiates the values for keyHash, fee and gameStarted
     * @param vrfCoordinator address of VRFCoordinator contract
     * @param linkToken address of LINK token contract
     * @param vrfFee the amount of LINK to send with the request
     * @param vrfKeyHash ID of public key against which randomness is generated
     */
    constructor(
        address initialOwner,
        address _rewardToken,
        address vrfCoordinator,
        address linkToken,
        bytes32 vrfKeyHash,
        uint256 vrfFee
    ) VRFConsumerBase(vrfCoordinator, linkToken) Ownable(initialOwner) {
        rewardToken = IERC20(_rewardToken);
        keyHash = vrfKeyHash;
        fee = vrfFee;
        gameStarted = false;
    }

    // function to register a user
    function registerUser() external {
        require(!isUserRegisterd[msg.sender], "User already registered");
        isUserRegisterd[msg.sender] = true;
        registeredUsers.push(msg.sender);
        emit UserRegistration(msg.sender);
    }

    /**
     * startGame starts the game by setting appropriate values for all the variables
     */
    function startGame(uint8 _maxEntries, uint256 _entryFee) external onlyOwner {
        // Check if there is a game already running
        require(!gameStarted, "Game is currently running");

        delete players;

        maxEntries = _maxEntries;

        gameStarted = true;

        entryFee = _entryFee;
        gameId += 1;
        emit GameStarted(gameId, maxEntries, entryFee);
    }

    /**
    joinGame is called when a player wants to enter the game
     */
    function joinGame() external payable {
        // check if user is already registered
        require(isUserRegisterd[msg.sender], "User not registered");
        // Check if a game is already running
        require(gameStarted, "Game has not been started yet");
        // Check if the value sent by the user matches the entryFee
        require(msg.value == entryFee, "Value sent is not equal to entryFee");

        // add the sender to the players list
        Player memory player = Player(msg.sender, 1);
        players.push(player);
        playerIndex[msg.sender] = players.length;

        emit PlayerJoined(gameId, msg.sender);

        // If the list is full start the winner selection process
        if (totalEntries >= maxEntries) {
          getRandomWinners();
        }
    }

    // Function to add entries for a participant
    function addEntries(uint256 entries) external {
        require(isUserRegisterd[msg.sender], "User not registered");
        // require(playerIndex[msg.sender]. != 0, "Has not joined game");
        // playerIndex[msg.sender].entries += entries;
        totalEntries += entries;
        emit EntriesAdded(msg.sender, entries);

        // If the list is full start the winner selection process
        if (totalEntries >= maxEntries) {
          getRandomWinners();
        }
    }


    /**
     * getRandomWinner is called to start the process of selecting a random winner
     */
    function getRandomWinners() private returns (bytes32 requestId) {
        // LINK is an internal interface for Link token found within the VRFConsumerBase
        // Here we use the balanceOF method from that interface to make sure that our
        // contract has enough link so that we can request the VRFCoordinator for randomness
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        require(
            !prizeDistributionStarted,
            "Prize distribution already started"
        );
        prizeDistributionStarted = true;
        // Make a request to the VRF coordinator.
        // requestRandomness is a function within the VRFConsumerBase
        // it starts the process of randomness generation
        return requestRandomness(keyHash, fee);
    }

    // Send ERC20 tokens to a winner
    function sendTokensToWinner(address player, uint256 amount) internal {
        require(rewardToken.balanceOf(address(this)) >= amount, "Insufficient Funds");
        rewardToken.transfer(player, amount);
    }
}
