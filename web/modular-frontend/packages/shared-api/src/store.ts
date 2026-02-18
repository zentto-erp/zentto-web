import { create } from 'zustand';

interface UserState {
  userName: string | null;
  userEmail: string | null;
  userId: string | null;
  isAdmin: boolean;
  sidebarCollapsed: boolean;
  setUserInfo: (userName: string | null, userEmail: string | null, userId: string | null) => void;
  setIsAdmin: (isAdmin: boolean) => void;
  setSidebarCollapsed: (collapsed: boolean) => void;
  toggleSidebar: () => void;
  reset: () => void;
}

export const useStore = create<UserState>((set) => ({
  userName: null,
  userEmail: null,
  userId: null,
  isAdmin: false,
  sidebarCollapsed: false,
  setUserInfo: (userName, userEmail, userId) => set({ userName, userEmail, userId }),
  setIsAdmin: (isAdmin) => set({ isAdmin }),
  setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed }),
  toggleSidebar: () => set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),
  reset: () => set({ userName: null, userEmail: null, userId: null, isAdmin: false, sidebarCollapsed: false }),
}));
