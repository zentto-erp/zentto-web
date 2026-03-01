import { StatusBar } from "expo-status-bar";
import RootNavigation from "./src/navigation";
import { Providers } from "./src/lib/providers";

export default function App() {
  return (
    <Providers>
      <StatusBar style="light" />
      <RootNavigation />
    </Providers>
  );
}
