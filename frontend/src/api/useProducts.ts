import axios from 'axios';
import { useQuery } from '@tanstack/react-query';
import { useAuthStore } from '../stores/authStore';

interface Product {
  id: number;
  name: string;
  brand: string;
  category: string;
  imageUrl: string;
  barcode: string;
  price: number;
  quantity: number;
  threshold: number;
}

const API_URL = 'http://localhost:5094/api';

export const useProducts = () => {
  const token = useAuthStore((state) => state.token);
  
  return useQuery({
    queryKey: ['products'],
    queryFn: async (): Promise<Product[]> => {
      try {
        console.log('Fetching products with token:', token);
        const { data } = await axios.get(`${API_URL}/products`, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
        console.log('Products response:', data);
        return data;
      } catch (error: any) {
        console.error('Erreur lors de la récupération des produits:', error);
        if (error.response) {
          console.error('Détails de l\'erreur:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          });
        }
        throw new Error('Erreur lors de la récupération des produits');
      }
    }
  });
}; 