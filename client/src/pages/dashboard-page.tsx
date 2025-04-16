import { useState } from "react";
import { useLocation } from "wouter";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/hooks/use-auth";
import { GameMatch, User } from "@shared/schema";
import { Gamepad2, Trophy, Users, Coins, Clock } from "lucide-react";
import { Navbar } from "@/components/layout/navbar";
import { BetModal } from "@/components/game/bet-modal";
import { Badge } from "@/components/ui/badge";
import { SEO } from "@/components/seo";

export default function DashboardPage() {
  const [_, setLocation] = useLocation();
  const { user } = useAuth();
  const [isBetModalOpen, setIsBetModalOpen] = useState(false);
  const [selectedGame, setSelectedGame] = useState<'tetris' | 'temple-runner' | 'street-fighter' | null>(null);

  // Add refetch interval to keep matches list up to date
  const { data: matches, isLoading: isMatchesLoading } = useQuery<GameMatch[]>({
    queryKey: ["/api/matches"],
    refetchInterval: 5000 // Refetch every 5 seconds
  });

  const { data: leaderboard } = useQuery<User[]>({
    queryKey: ["/api/leaderboard"],
  });

  const games = [
    {
      id: "tetris",
      name: "Tetris Battle",
      description: "Challenge players in real-time Tetris matches",
      icon: "🎮",
      background: "bg-gradient-to-r from-pink-500 to-purple-500",
      enabled: true
    },
    {
      id: "temple-runner",
      name: "Temple Runner",
      description: "Race through ancient temples collecting coins while avoiding obstacles",
      icon: "🏃",
      background: "bg-gradient-to-r from-yellow-500 to-orange-500",
      enabled: true
    },
    {
      id: "street-fighter",
      name: "Street Fighter",
      description: "Classic arcade fighting game with original moves and characters",
      icon: "👊",
      background: "bg-gradient-to-r from-red-500 to-orange-500",
      enabled: true
    },
    // Coming Soon Games
    {
      id: "chess",
      name: "Crypto Chess",
      description: "Strategic chess gameplay with blockchain-based tournaments and ratings",
      icon: "♟️",
      background: "bg-gradient-to-r from-blue-500 to-indigo-500",
      enabled: false,
      comingSoon: true
    },
    {
      id: "poker",
      name: "Web3 Poker",
      description: "Texas Hold'em poker with decentralized card shuffling and secure betting",
      icon: "🃏",
      background: "bg-gradient-to-r from-green-500 to-emerald-500",
      enabled: false,
      comingSoon: true
    },
    {
      id: "racing",
      name: "Blockchain Racing",
      description: "High-octane racing with NFT vehicles and customizable tracks",
      icon: "🏎️",
      background: "bg-gradient-to-r from-cyan-500 to-blue-500",
      enabled: false,
      comingSoon: true
    }
  ];

  const handlePractice = (gameId: string) => {
    switch (gameId) {
      case 'tetris':
        setLocation('/game/new');
        break;
      case 'temple-runner':
        setLocation('/temple-runner');
        break;
      case 'street-fighter':
        setLocation('/street-fighter/practice');
        break;
    }
  };

  const handleWager = (gameId: string) => {
    setSelectedGame(gameId as 'tetris' | 'temple-runner' | 'street-fighter');
    setIsBetModalOpen(true);
  };

  // Filter active matches where the current user is not the creator
  const activeMatches = matches?.filter(match =>
    match.status === "waiting" &&
    match.player1Id !== user?.id &&
    !match.isPractice
  ) || [];

  return (
    <div className="min-h-screen bg-background">
      {/* Dashboard SEO Meta Tags */}
      <SEO 
        title="Game Dashboard" 
        description="Play and wager on games including Tetris, Temple Runner, and Street Fighter. View your stats, join active matches, and check the leaderboard."
        type="website"
      />
      
      <Navbar />
      <main className="container mx-auto px-4 py-8">
        <h1 className="pixel-font text-4xl text-center mb-8 text-primary">
          Game Dashboard
        </h1>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Game Selection */}
          <div className="md:col-span-2 space-y-6">
            <div>
              <h2 className="text-2xl font-bold mb-4 flex items-center gap-2 pixel-font">
                <Gamepad2 className="h-6 w-6" />
                Choose Your Game
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {games.map((game) => (
                  <Card
                    key={game.id}
                    className={`game-card ${game.background} hover:border-primary transition-all duration-300 ${!game.enabled ? 'opacity-50' : ''}`}
                  >
                    <CardHeader>
                      <CardTitle className="flex items-center justify-between text-white">
                        <span className="flex items-center gap-2">
                          <span className="text-2xl">{game.icon}</span>
                          <span className="pixel-font text-sm">{game.name}</span>
                        </span>
                        <div className="flex gap-2">
                          {game.enabled ? (
                            <>
                              <Button
                                size="sm"
                                variant="secondary"
                                onClick={() => handlePractice(game.id)}
                                className="pixel-font text-xs"
                              >
                                Practice
                              </Button>
                              <Button
                                size="sm"
                                variant="default"
                                className="pixel-font text-xs bg-gradient-to-r from-yellow-500 to-amber-500"
                                onClick={() => handleWager(game.id)}
                              >
                                Wager
                              </Button>
                            </>
                          ) : game.comingSoon && (
                            <Badge 
                              variant="outline" 
                              className="bg-black/30 text-white border border-white/30 flex items-center gap-1 pixel-font"
                            >
                              <Clock className="h-3 w-3" />
                              Coming Soon
                            </Badge>
                          )}
                        </div>
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-white/80">{game.description}</p>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>

            {/* Active Matches */}
            <div>
              <h2 className="text-2xl font-bold mb-4 flex items-center gap-2 pixel-font">
                <Users className="h-6 w-6" />
                Available Wager Matches
              </h2>
              <div className="space-y-4">
                {isMatchesLoading ? (
                  <p className="text-center text-muted-foreground">Loading matches...</p>
                ) : activeMatches.length > 0 ? (
                  activeMatches.map((match) => (
                    <Card key={match.id} className="hover:border-primary transition-all duration-300">
                      <CardContent className="flex justify-between items-center p-4">
                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <Coins className="h-4 w-4" />
                            <p className="pixel-font text-sm">
                              {match.betAmount} {match.betType === 'xp' ? 'XP' : 'ETH'}
                            </p>
                          </div>
                          <p className="text-sm text-muted-foreground">
                            Created by Player #{match.player1Id}
                          </p>
                        </div>
                        <Button
                          onClick={() => setLocation(`/game/${match.id}`)}
                          className="pixel-font"
                        >
                          Accept Challenge
                        </Button>
                      </CardContent>
                    </Card>
                  ))
                ) : (
                  <p className="text-center text-muted-foreground">
                    No active wager matches available
                  </p>
                )}
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Player Stats */}
            <Card>
              <CardHeader>
                <CardTitle className="pixel-font">Your Stats</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Games Played</span>
                  <span className="font-semibold">{user?.gamesPlayed || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Games Won</span>
                  <span className="font-semibold">{user?.gamesWon || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Total Score</span>
                  <span className="font-semibold">{user?.score || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Available XP</span>
                  <span className="font-semibold">{user?.xp || 0}</span>
                </div>
              </CardContent>
            </Card>

            {/* Leaderboard */}
            <Card>
              <CardHeader>
                <CardTitle className="pixel-font flex items-center gap-2">
                  <Trophy className="h-5 w-5" />
                  Leaderboard
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {leaderboard?.map((player, index) => (
                    <div key={player.id} className="flex justify-between items-center">
                      <div className="flex items-center gap-2">
                        <span className={`font-bold ${index === 0 ? 'text-yellow-500' : index === 1 ? 'text-gray-400' : index === 2 ? 'text-amber-600' : 'text-muted-foreground'}`}>
                          #{index + 1}
                        </span>
                        <span className="pixel-font text-xs">{player.username || `Player #${player.id}`}</span>
                      </div>
                      <span className="font-semibold">{player.score} pts</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
      <BetModal 
        open={isBetModalOpen} 
        onClose={() => {
          setIsBetModalOpen(false);
          setSelectedGame(null);
        }}
        gameType={selectedGame || 'tetris'}
      />
    </div>
  );
}
