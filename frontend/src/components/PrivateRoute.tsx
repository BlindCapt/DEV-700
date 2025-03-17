import { useAuthStore } from '../stores/authStore'
import { Navigate } from 'react-router-dom'

export function PrivateRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated)

  // Rediriger vers la page de connexion si l'utilisateur n'est pas authentifié
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  // Sinon, afficher le contenu normal
  return <>{children}</>
} 