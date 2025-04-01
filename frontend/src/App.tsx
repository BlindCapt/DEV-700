import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { Dashboard } from './pages/Dashboard';
import Products from './pages/Products';
import { Users } from './pages/Users';
import { Invoices } from './pages/Invoices';
import { Login } from './pages/Login';
import { Layout } from './components/Layout';
import { PrivateRoute } from './components/PrivateRoute';
import { useEffect } from 'react'
import { Toaster } from '@/components/ui/sonner';

// Configuration de React Query pour mettre à jour fréquemment les données
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: true,
      refetchOnMount: true,
      refetchOnReconnect: true,
      staleTime: 0, // Forcer le rafraîchissement à chaque montage de composant
      retry: 1,
    },
  },
});

function App() {
  useEffect(() => {
    document.documentElement.classList.add('dark')
  }, [])

  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={
            <PrivateRoute>
              <Layout>
                <Dashboard />
              </Layout>
            </PrivateRoute>
          } />
          <Route path="/products" element={
            <PrivateRoute>
              <Layout>
                <Products />
              </Layout>
            </PrivateRoute>
          } />
          <Route path="/users" element={
            <PrivateRoute>
              <Layout>
                <Users />
              </Layout>
            </PrivateRoute>
          } />
          <Route path="/invoices" element={
            <PrivateRoute>
              <Layout>
                <Invoices />
              </Layout>
            </PrivateRoute>
          } />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
      <ReactQueryDevtools />
      <Toaster />
    </QueryClientProvider>
  );
}

export default App;
