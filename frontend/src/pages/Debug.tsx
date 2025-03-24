import { useState, useEffect } from 'react';
import { useAuthStore } from '../stores/authStore';
import axios from 'axios';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';

export const DebugPage = () => {
  const token = useAuthStore((state) => state.token);
  const user = useAuthStore((state) => state.user);
  const [webUsersResponse, setWebUsersResponse] = useState<any>(null);
  const [mobileUsersResponse, setMobileUsersResponse] = useState<any>(null);
  const [webUsersError, setWebUsersError] = useState<string | null>(null);
  const [mobileUsersError, setMobileUsersError] = useState<string | null>(null);
  const [tokenInfo, setTokenInfo] = useState<any>(null);
  
  // Décoder le token JWT pour afficher son contenu
  useEffect(() => {
    if (token) {
      try {
        // Decode JWT token (format: header.payload.signature)
        const payload = token.split('.')[1];
        const decodedPayload = JSON.parse(atob(payload));
        setTokenInfo(decodedPayload);
      } catch (error) {
        console.error('Erreur lors du décodage du token:', error);
        setTokenInfo({ error: 'Impossible de décoder le token' });
      }
    }
  }, [token]);
  
  const testWebUsersAPI = async () => {
    setWebUsersError(null);
    try {
      const response = await axios.get('http://localhost:5094/api/web/users', {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      setWebUsersResponse(response.data);
    } catch (error: any) {
      console.error('Erreur API web users:', error);
      setWebUsersError(error.response ? 
        `Erreur ${error.response.status}: ${JSON.stringify(error.response.data)}` : 
        `Erreur: ${error.message}`);
    }
  };
  
  const testMobileUsersAPI = async () => {
    setMobileUsersError(null);
    try {
      const response = await axios.get('http://localhost:5094/api/mobile/users', {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      setMobileUsersResponse(response.data);
    } catch (error: any) {
      console.error('Erreur API mobile users:', error);
      setMobileUsersError(error.response ? 
        `Erreur ${error.response.status}: ${JSON.stringify(error.response.data)}` : 
        `Erreur: ${error.message}`);
    }
  };
  
  return (
    <div className="space-y-8 p-8">
      <h1 className="text-3xl font-bold">Page de débogage</h1>
      
      <Card>
        <CardHeader>
          <CardTitle>Informations d'authentification</CardTitle>
          <CardDescription>Détails sur le token et l'utilisateur</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div>
              <h3 className="text-lg font-medium">État de connexion:</h3>
              <p>{token ? 'Connecté' : 'Non connecté'}</p>
            </div>
            
            <div>
              <h3 className="text-lg font-medium">Token JWT:</h3>
              <div className="max-h-40 overflow-auto p-2 bg-gray-100 dark:bg-gray-800 rounded">
                <pre className="whitespace-pre-wrap break-all">{token || 'Aucun token'}</pre>
              </div>
            </div>
            
            <div>
              <h3 className="text-lg font-medium">Contenu du token:</h3>
              <div className="max-h-40 overflow-auto p-2 bg-gray-100 dark:bg-gray-800 rounded">
                <pre className="whitespace-pre-wrap">{tokenInfo ? JSON.stringify(tokenInfo, null, 2) : 'Aucune information'}</pre>
              </div>
            </div>
            
            <div>
              <h3 className="text-lg font-medium">Utilisateur:</h3>
              <div className="max-h-40 overflow-auto p-2 bg-gray-100 dark:bg-gray-800 rounded">
                <pre className="whitespace-pre-wrap">{user ? JSON.stringify(user, null, 2) : 'Aucune information'}</pre>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
      
      <Card>
        <CardHeader>
          <CardTitle>Test des APIs</CardTitle>
          <CardDescription>Tester les appels aux APIs utilisateurs</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-8">
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-medium">API Utilisateurs Web:</h3>
                <Button onClick={testWebUsersAPI}>Tester /api/web/users</Button>
              </div>
              
              {webUsersError && (
                <div className="p-4 bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200 rounded">
                  <h4 className="font-medium">Erreur:</h4>
                  <pre className="whitespace-pre-wrap text-sm">{webUsersError}</pre>
                </div>
              )}
              
              {webUsersResponse && (
                <div className="p-4 bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 rounded">
                  <h4 className="font-medium">Réponse:</h4>
                  <div className="max-h-40 overflow-auto">
                    <pre className="whitespace-pre-wrap text-sm">{JSON.stringify(webUsersResponse, null, 2)}</pre>
                  </div>
                </div>
              )}
            </div>
            
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-medium">API Utilisateurs Mobile:</h3>
                <Button onClick={testMobileUsersAPI}>Tester /api/mobile/users</Button>
              </div>
              
              {mobileUsersError && (
                <div className="p-4 bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200 rounded">
                  <h4 className="font-medium">Erreur:</h4>
                  <pre className="whitespace-pre-wrap text-sm">{mobileUsersError}</pre>
                </div>
              )}
              
              {mobileUsersResponse && (
                <div className="p-4 bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 rounded">
                  <h4 className="font-medium">Réponse:</h4>
                  <div className="max-h-40 overflow-auto">
                    <pre className="whitespace-pre-wrap text-sm">{JSON.stringify(mobileUsersResponse, null, 2)}</pre>
                  </div>
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default DebugPage; 