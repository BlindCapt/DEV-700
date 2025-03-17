import { useAuthStore } from '../stores/authStore'

export function PrivateRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated)

  // Retourner simplement les enfants sans redirection
  return <>{children}</>
} 