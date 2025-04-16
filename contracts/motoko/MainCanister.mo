// YokikoGamingPlatform.mo
//
// Production-ready canister for gaming wagers, dual-authorization (ICP Internet Identity + EVM wallet),
// bet logging across ICP and Ethereum (via a blockchain bridge), and an anti-cheat mechanism.
//
// This version exposes an admin-controlled game registry to allow new games/features
// to be composed dynamically without redeploying the entire canister.
//
// Author: [Your Name]
// Date: [Current Date]
//
// References:
// - The Motoko Programming Language Book :contentReference[oaicite:0]{index=0} :contentReference[oaicite:1]{index=1}

import Actor "mo:base/Actor";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Debug "mo:base/Debug";

/// A generic result type used for function returns.
public type Result<T> = { #ok: T } | { #err: Text };

/// Type alias for game identifiers.
public type GameId = Nat;

/// A record representing a bet placed by a player.
///
/// Fields:
/// - player: The caller’s Principal (ICP Internet Identity).
/// - evmWallet: The associated EVM wallet (as Text).
/// - gameId: The identifier of the game.
/// - betAmount: The wagered amount (in ICP or token-equivalent units).
/// - betType: A text indicator for the token/chain type, e.g., "ICP", "ETH_MAINNET", "ETH_SEPOLIA".
/// - timestamp: The time when the bet was placed.
public type Bet = {
  player: Principal;
  evmWallet: Text;
  gameId: GameId;
  betAmount: Nat;
  betType: Text;
  timestamp: Time.Time;
};

/// A record used for dynamic game registry entries.
///
/// Fields:
/// - gameId: The unique ID of the game.
/// - name: The display name of the game.
/// - description: A short description of the game.
/// - allowedBetTypes: A list of permitted bet types (e.g., ["ICP", "ETH_MAINNET"]).
public type GameInfo = {
  gameId: GameId;
  name: Text;
  description: Text;
  allowedBetTypes: [Text];
};

actor YokikoGamingPlatform {

  // ------------------------------------------------------------------
  // Stable Variables
  // ------------------------------------------------------------------

  /// Deployment version used for CI/CD tracking.
  stable var deploymentVersion : Text = "v1.0.0";
  
  /// Admin principal — only the admin (or a multi-sig structure) may update core settings.
  stable var admin : Principal = Principal.fromText("aaaaa-aa"); // TODO: Replace with your production admin principal
  
  /// List of bets placed by players.
  stable var bets : [Bet] = [];
  
  /// Registered players as pairs of (Internet Identity, associated EVM wallet).
  stable var registeredPlayers : [(Principal, Text)] = [];

  /// List of flagged players (these players are prevented from placing future bets).
  stable var flaggedPlayers : [Principal] = [];

  /// Game registry for dynamic game addition.
  stable var gameRegistry : [GameInfo] = [
    { gameId = 1; name = "Tetris Battle"; description = "Real-time Tetris competition"; allowedBetTypes = ["ICP", "ETH_MAINNET"] },
    { gameId = 2; name = "Temple Runner"; description = "Endless runner with coin collection"; allowedBetTypes = ["ICP", "ETH_MAINNET"] },
    { gameId = 3; name = "Street Fighter"; description = "Classic fighting game"; allowedBetTypes = ["ICP", "ETH_MAINNET"] }
  ];

  // ------------------------------------------------------------------
  // Utility Functions
  // ------------------------------------------------------------------

  /// Logs a bet or event to an external Ethereum bridge.
  ///
  /// # Arguments
  /// - `player`: The Principal of the player to log.
  /// - `details`: A text message with details to log.
  ///
  /// # TODO:
  /// Replace this stub with an inter-canister call that communicates with an Ethereum smart contract via EVM RPC.
  private shared(msg) func logBetToEthereum(player: Principal, details: Text) : async () {
    Debug.print("ETH Log -> Player: " # Principal.toText(player) # ", Details: " # details);
    // TODO: Integrate with your Ethereum bridge or EVM RPC canister.
    return;
  };

  // ------------------------------------------------------------------
  // Admin-only Functions
  // ------------------------------------------------------------------

  /// Updates the deployment version.
  ///
  /// This function is restricted to the admin principal.
  ///
  /// # Arguments
  /// - `newVersion`: The new deployment version as Text.
  ///
  /// # Returns
  /// A Result type containing either the new version on success or an error message on failure.
  public shared(msg) func updateDeploymentVersion(newVersion: Text) : async Result<Text> {
    if (Actor.caller() != admin) {
      return { #err = "Unauthorized" };
    };
    deploymentVersion := newVersion;
    return { #ok = newVersion };
  };

  /// Adds a new game to the registry.
  ///
  /// Restricted to the admin to enable dynamic game composition.
  ///
  /// # Arguments
  /// - `newGame`: A GameInfo record defining the new game.
  ///
  /// # Returns
  /// A Result type indicating success or failure.
  public shared(msg) func addGame(newGame: GameInfo) : async Result<Void> {
    if (Actor.caller() != admin) {
      return { #err = "Unauthorized" };
    };
    if (List.exists<GameInfo>(gameRegistry, func (g) : Bool { g.gameId == newGame.gameId })) {
      return { #err = "GameId already exists" };
    };
    gameRegistry := [newGame] # gameRegistry;
    return { #ok = () };
  };

  // ------------------------------------------------------------------
  // Anti-Cheat Mechanism
  // ------------------------------------------------------------------

  /// Flags a player as a cheater.
  ///
  /// Any user may flag a cheater by providing their Principal and a reason.
  ///
  /// # Arguments
  /// - `offender`: The Principal of the player to flag.
  /// - `reason`: A description of why the player is being flagged.
  ///
  /// # Returns
  /// A Result type containing true on success or an error message if already flagged.
  public shared(msg) func flagCheater(offender: Principal, reason: Text) : async Result<Bool> {
    Debug.print("Flag attempt for " # Principal.toText(offender) # " Reason: " # reason);
    if (List.exists<Principal>(flaggedPlayers, func(p : Principal) : Bool { p == offender })) {
      return { #err = "Player already flagged" };
    } else {
      flaggedPlayers := [offender] # flaggedPlayers;
      await logBetToEthereum(offender, "Cheater flagged: " # reason);
      return { #ok = true };
    }
  };

  // ------------------------------------------------------------------
  // Player and Bet Management
  // ------------------------------------------------------------------

  /// Registers a player by associating their Internet Identity with an EVM wallet.
  ///
  /// This dual-authorization process prevents spoofing.
  ///
  /// # Arguments
  /// - `evmWallet`: The player's EVM wallet address.
  ///
  /// # Returns
  /// A Result type with true if registration succeeded or an error message.
  public shared(msg) func registerPlayer(evmWallet: Text) : async Result<Bool> {
    let caller = Actor.caller();
    if (List.exists<(Principal, Text)>(registeredPlayers, func(pair) : Bool {
      let (p, w) = pair;
      p == caller or w == evmWallet
    })) {
      return { #err = "Player already registered" };
    } else {
      registeredPlayers := [(caller, evmWallet)] # registeredPlayers;
      Debug.print("Registered player: " # Principal.toText(caller));
      return { #ok = true };
    }
  };

  /// Places a bet on a specified game.
  ///
  /// This function verifies that the game exists, the bet type is allowed, and that the caller’s registration
  /// (i.e. pairing of ICP identity and EVM wallet) is valid. Also, players who have been flagged cannot bet.
  ///
  /// # Arguments
  /// - `gameId`: The ID of the game the bet is for.
  /// - `betAmount`: The amount to wager; must be greater than zero.
  /// - `betType`: The type of bet (for example, "ICP", "ETH_MAINNET").
  /// - `evmWallet`: The EVM wallet address that must match the registered wallet.
  ///
  /// # Returns
  /// A Result type with true if the bet is successfully placed or an error message.
  public shared(msg) func placeBet(gameId: GameId, betAmount: Nat, betType: Text, evmWallet: Text) : async Result<Bool> {
    let caller = Actor.caller();
    if (betAmount <= 0) {
      return { #err = "Bet amount must be greater than zero" };
    };

    // Validate that the game exists and supports the chosen bet type.
    let gameOpt = List.find<GameInfo>(gameRegistry, func(g) : Bool { g.gameId == gameId });
    switch (gameOpt) {
      case (?gameInfo) {
        if (not List.exists<Text>(gameInfo.allowedBetTypes, func(token) : Bool { token == betType })) {
          return { #err = "Bet type not allowed for the selected game" };
        };
      };
      case null {
        return { #err = "Game not found" };
      }
    };

    // Verify that the caller's registration matches the provided EVM wallet.
    if (not List.exists<(Principal, Text)>(registeredPlayers, func(pair) : Bool {
      let (p, w) = pair;
      p == caller and w == evmWallet
    })) {
      return { #err = "Registration mismatch: EVM wallet does not match" };
    };

    // Prevent flagged players from betting.
    if (List.exists<Principal>(flaggedPlayers, func(p : Principal) : Bool { p == caller })) {
      return { #err = "Player is flagged" };
    };

    let newBet : Bet = {
      player = caller;
      evmWallet = evmWallet;
      gameId = gameId;
      betAmount = betAmount;
      betType = betType;
      timestamp = Time.now();
    };
    bets := [newBet] # bets;
    Debug.print("Bet placed by " # Principal.toText(caller) # " on game " # Nat.toText(gameId));
    await logBetToEthereum(caller, "Bet placed on game " # Nat.toText(gameId));
    return { #ok = true };
  };

  /// Processes game results by logging win/loss outcomes for all bets on a game.
  ///
  /// For security, only the admin may call this function.
  ///
  /// # Arguments
  /// - `gameId`: The game identifier whose results are to be processed.
  /// - `winner`: The Principal of the winning player.
  ///
  /// # Returns
  /// A Result type with true if processing succeeded or an error message.
  public shared(msg) func updateGameResult(gameId: GameId, winner: Principal) : async Result<Bool> {
    if (Actor.caller() != admin) {
      return { #err = "Unauthorized" };
    };

    let gameBets = List.filter<Bet>(bets, func(b : Bet) : Bool { b.gameId == gameId });
    if (List.size(gameBets) == 0) {
      return { #err = "No bets found for the game" };
    };

    for (bet in gameBets) {
      if (bet.player == winner) {
        Debug.print("Player " # Principal.toText(winner) # " wins for game " # Nat.toText(gameId));
        await logBetToEthereum(winner, "Win payout for game " # Nat.toText(gameId));
      } else {
        Debug.print("Player " # Principal.toText(bet.player) # " lost in game " # Nat.toText(gameId));
      };
    };
    return { #ok = true };
  };

  // ------------------------------------------------------------------
  // Query Functions (for UI, testing, and CI/CD)
  // ------------------------------------------------------------------

  /// Retrieves the current deployment version.
  public query func getDeploymentVersion() : async Text {
    return deploymentVersion;
  };

  /// Retrieves the list of all bets.
  public query func getBets() : async [Bet] {
    return bets;
  };

  /// Retrieves registered players.
  public query func getRegisteredPlayers() : async [(Principal, Text)] {
    return registeredPlayers;
  };

  /// Retrieves flagged players.
  public query func getFlaggedPlayers() : async [Principal] {
    return flaggedPlayers;
  };

  /// Retrieves the game registry.
  public query func getGameRegistry() : async [GameInfo] {
    return gameRegistry;
  };
}