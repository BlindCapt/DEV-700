import axios from 'axios';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuthStore } from '../stores/authStore';

// Types pour les utilisateurs web
export interface WebUser {
  id: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  role: string;
  createdAt: string;
  lastLogin?: string;
}

export interface CreateWebUserDto {
  username: string;
  password: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'Manager' | 'Employee';
}

export interface UpdateWebUserDto {
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'Manager' | 'Employee';
  password?: string; // Optionnel, ne mettre à jour que si non vide
}

// Types pour les utilisateurs mobiles
export interface MobileUser {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  phoneNumber: string;
  isActive: boolean;
  createdAt: string;
  lastLogin?: string;
}

export interface CreateMobileUserDto {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  phoneNumber: string;
}

export interface UpdateMobileUserDto {
  email: string;
  firstName: string;
  lastName: string;
  phoneNumber: string;
  isActive: boolean;
}

const API_URL = 'http://localhost:5094/api';

// Hook pour récupérer les utilisateurs web
export const useWebUsers = () => {
  const token = useAuthStore((state) => state.token);

  return useQuery({
    queryKey: ['webUsers'],
    queryFn: async (): Promise<WebUser[]> => {
      try {
        console.log('Appel GET /web/users avec token:', token);
        const { data } = await axios.get(`${API_URL}/web/users`, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
        console.log('Réponse /web/users:', data);
        return data;
      } catch (error: any) {
        console.error('Erreur lors de la récupération des utilisateurs web:', error);
        if (error.response) {
          console.error('Détails de l\'erreur:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          });
        }
        throw new Error(`Erreur lors de la récupération des utilisateurs web: ${error.message}`);
      }
    },
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    staleTime: 30 * 1000 // Les données sont considérées comme obsolètes après 30 secondes
  });
};

// Hook pour récupérer les utilisateurs mobiles
export const useMobileUsers = () => {
  const token = useAuthStore((state) => state.token);

  return useQuery({
    queryKey: ['mobileUsers'],
    queryFn: async (): Promise<MobileUser[]> => {
      try {
        console.log('Appel GET /mobile/users avec token:', token);
        const { data } = await axios.get(`${API_URL}/mobile/users`, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
        console.log('Réponse /mobile/users:', data);
        return data;
      } catch (error: any) {
        console.error('Erreur lors de la récupération des utilisateurs mobiles:', error);
        if (error.response) {
          console.error('Détails de l\'erreur:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          });
        }
        throw new Error(`Erreur lors de la récupération des utilisateurs mobiles: ${error.message}`);
      }
    },
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    staleTime: 30 * 1000 // Les données sont considérées comme obsolètes après 30 secondes
  });
};

// Hook pour créer un utilisateur web
export const useCreateWebUser = () => {
  const queryClient = useQueryClient();
  const token = useAuthStore((state) => state.token);

  return useMutation({
    mutationFn: async (newUser: CreateWebUserDto) => {
      try {
        console.log('Appel POST /web/users avec token:', token);
        // Convertir le rôle en valeur numérique pour l'API
        const roleValue = newUser.role === 'Manager' ? 0 : 1;
        
        // Préparer l'objet à envoyer à l'API avec le rôle converti
        const apiUser = {
          ...newUser,
          role: roleValue
        };
        
        console.log('Données:', apiUser);
        const { data } = await axios.post(`${API_URL}/web/users`, apiUser, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
        console.log('Réponse création utilisateur web:', data);
        return data;
      } catch (error: any) {
        console.error('Erreur lors de la création de l\'utilisateur web:', error);
        if (error.response) {
          console.error('Détails de l\'erreur:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          });
        }
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['webUsers'] });
    }
  });
};

// Hook pour créer un utilisateur mobile
export const useCreateMobileUser = () => {
  const queryClient = useQueryClient();
  const token = useAuthStore((state) => state.token);

  return useMutation({
    mutationFn: async (newUser: CreateMobileUserDto) => {
      try {
        console.log('Appel POST /mobile/users avec token:', token);
        console.log('Données:', newUser);
        const { data } = await axios.post(`${API_URL}/mobile/users`, newUser, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
        console.log('Réponse création utilisateur mobile:', data);
        return data;
      } catch (error: any) {
        console.error('Erreur lors de la création de l\'utilisateur mobile:', error);
        if (error.response) {
          console.error('Détails de l\'erreur:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          });
        }
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['mobileUsers'] });
    }
  });
};

// Hook pour mettre à jour un utilisateur web
export const useUpdateWebUser = () => {
  const queryClient = useQueryClient();
  const token = useAuthStore((state) => state.token);

  return useMutation({
    mutationFn: async ({ id, user }: { id: number; user: UpdateWebUserDto }) => {
      try {
        console.log(`Appel PUT /web/users/${id} avec token:`, token);
        // Convertir le rôle en valeur numérique pour l'API
        const roleValue = user.role === 'Manager' ? 0 : 1;
        
        // Préparer l'objet à envoyer à l'API avec le rôle converti
        const apiUser = {
          ...user,
          role: roleValue
        };
        
        console.log('Données:', apiUser);
        const { data } = await axios.put(`${API_URL}/web/users/${id}`, apiUser, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
        console.log('Réponse mise à jour utilisateur web:', data);
        return data;
      } catch (error: any) {
        console.error('Erreur lors de la mise à jour de l\'utilisateur web:', error);
        if (error.response) {
          console.error('Détails de l\'erreur:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          });
        }
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['webUsers'] });
    }
  });
};

// Hook pour supprimer un utilisateur web
export const useDeleteWebUser = () => {
  const queryClient = useQueryClient();
  const token = useAuthStore((state) => state.token);

  return useMutation({
    mutationFn: async (id: number) => {
      try {
        console.log(`Appel DELETE /web/users/${id} avec token:`, token);
        const { data } = await axios.delete(`${API_URL}/web/users/${id}`, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
        console.log('Réponse suppression utilisateur web:', data);
        return data;
      } catch (error: any) {
        console.error('Erreur lors de la suppression de l\'utilisateur web:', error);
        if (error.response) {
          console.error('Détails de l\'erreur:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          });
        }
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['webUsers'] });
    }
  });
};

// Hook pour mettre à jour un utilisateur mobile
export const useUpdateMobileUser = () => {
  const queryClient = useQueryClient();
  const token = useAuthStore((state) => state.token);

  return useMutation({
    mutationFn: async ({ id, user }: { id: number; user: UpdateMobileUserDto }) => {
      try {
        console.log(`Appel PUT /mobile/users/${id} avec token:`, token);
        console.log('Données:', user);
        const { data } = await axios.put(`${API_URL}/mobile/users/${id}`, user, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
        console.log('Réponse mise à jour utilisateur mobile:', data);
        return data;
      } catch (error: any) {
        console.error('Erreur lors de la mise à jour de l\'utilisateur mobile:', error);
        if (error.response) {
          console.error('Détails de l\'erreur:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          });
        }
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['mobileUsers'] });
    }
  });
};

// Hook pour supprimer un utilisateur mobile
export const useDeleteMobileUser = () => {
  const queryClient = useQueryClient();
  const token = useAuthStore((state) => state.token);

  return useMutation({
    mutationFn: async (id: number) => {
      try {
        console.log(`Appel DELETE /mobile/users/${id} avec token:`, token);
        const { data } = await axios.delete(`${API_URL}/mobile/users/${id}`, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
        console.log('Réponse suppression utilisateur mobile:', data);
        return data;
      } catch (error: any) {
        console.error('Erreur lors de la suppression de l\'utilisateur mobile:', error);
        if (error.response) {
          console.error('Détails de l\'erreur:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          });
        }
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['mobileUsers'] });
    }
  });
}; 