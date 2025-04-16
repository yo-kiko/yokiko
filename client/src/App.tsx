import { Switch, Route } from "wouter";
import { SEO } from "@/components/seo";
import { Providers } from "@/components/providers";
import NotFound from "@/pages/not-found";
import SplashPage from "@/pages/splash-page";
import NewAuthPage from "@/pages/new-auth-page";
import DashboardPage from "@/pages/dashboard-page";
import GamePage from "@/pages/game-page";
import NewGamePage from "@/pages/new-game-page";
import TempleRunnerPage from "@/pages/temple-runner-page";
import StreetFighterPage from "@/pages/street-fighter-page";
import CreatorApplication from "@/pages/creator-application";
import { ProtectedRoute } from "./lib/protected-route";

function Router() {
  return (
    <Switch>
      <Route path="/" component={SplashPage} />
      <Route path="/auth" component={NewAuthPage} />
      <ProtectedRoute path="/dashboard" component={DashboardPage} />
      <ProtectedRoute path="/game/new" component={NewGamePage} />
      <ProtectedRoute path="/game/:id" component={GamePage} />
      <ProtectedRoute path="/temple-runner" component={TempleRunnerPage} />
      <ProtectedRoute path="/street-fighter/practice" component={StreetFighterPage} />
      <ProtectedRoute path="/street-fighter/:id" component={StreetFighterPage} />
      <ProtectedRoute path="/creator-application" component={CreatorApplication} />
      <Route component={NotFound} />
    </Switch>
  );
}

function App() {
  return (
    <div className="min-h-screen bg-background">
      {/* Global SEO configuration */}
      <SEO />
      
      <Providers>
        <Router />
      </Providers>
    </div>
  );
}

export default App;