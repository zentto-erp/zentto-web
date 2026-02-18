'use client';

import { createTheme, ThemeProvider, CssBaseline } from "@mui/material";
import { AppRouterCacheProvider } from "@mui/material-nextjs/v15-appRouter";
import type { ReactNode } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { SessionProvider } from "next-auth/react";
import { AuthProvider } from "@/app/authentication/AuthContext";
import ToastProvider from "./ToastProvider";
import LocalizationProviderWrapper from "./LocalizationProviderWrapper";
import { Toaster } from "react-hot-toast";
import theme from "../../theme";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // 1 minuto
      refetchOnWindowFocus: false,
    },
  },
});

export function AppProviders({ children }: { children: ReactNode }) {
  return (
    <AppRouterCacheProvider options={{ enableCssLayer: true }}>
      <SessionProvider>
        <AuthProvider>
          <ThemeProvider theme={theme}>
            <CssBaseline />
            <LocalizationProviderWrapper>
              <QueryClientProvider client={queryClient}>
                <ToastProvider>
                  {children}
                  <Toaster
                    position="bottom-center"
                    reverseOrder={false}
                    gutter={8}
                    toastOptions={{
                      duration: 3000,
                      style: {
                        background: '#363636',
                        color: '#fff',
                      },
                    }}
                  />
                </ToastProvider>
              </QueryClientProvider>
            </LocalizationProviderWrapper>
          </ThemeProvider>
        </AuthProvider>
      </SessionProvider>
    </AppRouterCacheProvider>
  );
}
