import axios from 'axios';
import { useQuery } from '@tanstack/react-query';

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
  return useQuery({
    queryKey: ['products'],
    queryFn: async (): Promise<Product[]> => {
      try {
        const { data } = await axios.get(`${API_URL}/products`);
        return data;
      } catch (error) {
        throw new Error('Erreur lors de la récupération des produits');
      }
    }
  });
}; 