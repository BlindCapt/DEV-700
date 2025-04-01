import axios from 'axios';
import { useQuery } from '@tanstack/react-query';

// Typages pour les KPI
export interface KpiData {
  kpis: {
    totalRevenue: number;
    totalOrders: number;
    averageOrderValue: number;
    lowStockProducts: number;
    activeUsers: number;
  };
  charts: {
    revenueByMonth: {
      month: string;
      monthShort: string;
      revenue: number;
    }[];
    topSellingProducts: {
      product: string;
      quantity: number;
      revenue: number;
    }[];
    ordersByStatus: {
      status: string;
      value: number;
    }[];
    userGrowth: {
      month: string;
      monthShort: string;
      users: number;
    }[];
    productCategories: {
      category: string;
      value: number;
    }[];
  };
}

// Données mockées comme fallback
const mockData: KpiData = {
  kpis: {
    totalRevenue: 125780.45,
    totalOrders: 842,
    averageOrderValue: 149.38,
    lowStockProducts: 12,
    activeUsers: 178
  },
  charts: {
    revenueByMonth: [
      { month: 'Janvier', monthShort: 'Jan', revenue: 8250.36 },
      { month: 'Février', monthShort: 'Fév', revenue: 9420.55 },
      { month: 'Mars', monthShort: 'Mar', revenue: 11350.25 },
      { month: 'Avril', monthShort: 'Avr', revenue: 10840.75 },
      { month: 'Mai', monthShort: 'Mai', revenue: 12560.30 },
      { month: 'Juin', monthShort: 'Juin', revenue: 14780.90 }
    ],
    ordersByStatus: [
      { status: 'completed', value: 520 },
      { status: 'processing', value: 184 },
      { status: 'pending', value: 95 },
      { status: 'cancelled', value: 43 }
    ],
    topSellingProducts: [
      { product: 'Écran LED 27 pouces', quantity: 142, revenue: 28400 },
      { product: 'Casque audio sans fil', quantity: 98, revenue: 14700 },
      { product: 'Carte graphique RTX 4070', quantity: 56, revenue: 39200 },
      { product: 'SSD 1To', quantity: 89, revenue: 13350 },
      { product: 'Clavier mécanique RGB', quantity: 76, revenue: 9120 }
    ],
    userGrowth: [
      { month: 'Janvier', monthShort: 'Jan', users: 25 },
      { month: 'Février', monthShort: 'Fév', users: 32 },
      { month: 'Mars', monthShort: 'Mar', users: 41 },
      { month: 'Avril', monthShort: 'Avr', users: 38 },
      { month: 'Mai', monthShort: 'Mai', users: 45 },
      { month: 'Juin', monthShort: 'Juin', users: 53 }
    ],
    productCategories: [
      { category: 'Électronique', value: 245 },
      { category: 'Accessoires', value: 187 },
      { category: 'Périphériques', value: 124 },
      { category: 'Composants', value: 98 },
      { category: 'Audio', value: 65 }
    ]
  }
};

// Fonction pour formater un montant en euros
export const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR',
  }).format(amount);
};

// URL de base de l'API
const API_BASE_URL = process.env.NODE_ENV === 'development' 
  ? 'http://localhost:5094' // URL locale pour le développement
  : ''; // URL relative pour la production

// Fonction pour récupérer les données des KPI
export const fetchDashboardKPI = async (): Promise<KpiData> => {
  try {
    const url = `${API_BASE_URL}/api/kpi`;
    
    // Récupérer le token d'authentification
    const token = localStorage.getItem('token');
    if (!token) {
      throw new Error('Authentification requise');
    }
    
    const headers = {
      Authorization: `Bearer ${token}`,
    };
    
    const response = await axios.get(url, { headers });
    
    // Traitement des données de revenus mensuels pour assurer des valeurs numériques
    if (response.data && response.data.charts && response.data.charts.revenueByMonth) {
      // Forcer la conversion en nombre si nécessaire
      response.data.charts.revenueByMonth = response.data.charts.revenueByMonth.map(
        (month: any) => {
          // S'assurer que les revenus sont des nombres avec 2 décimales
          const numericRevenue = typeof month.revenue === 'string' 
            ? parseFloat(month.revenue) 
            : Number(month.revenue);
          
          return {
            ...month,
            revenue: parseFloat(numericRevenue.toFixed(2))
          };
        }
      );
    }
    
    return response.data;
  } catch (error) {
    console.error('Erreur lors de la récupération des données KPI:', error);
    throw error;
  }
};

// Hook React Query pour charger les KPI avec mise en cache
export const useKpiData = () => {
  return useQuery({
    queryKey: ['kpi', 'dashboard'],
    queryFn: fetchDashboardKPI,
    refetchOnWindowFocus: false, // Désactiver le rafraîchissement automatique au focus
    refetchOnMount: 'always', // Rafraîchir uniquement au montage initial
    refetchOnReconnect: true,
    retry: 1, // Essayer une fois de plus en cas d'échec
    staleTime: 60 * 1000, // Considérer les données comme fraîches pendant 1 minute
    gcTime: 5 * 60 * 1000, // Conserver en cache pendant 5 minutes (anciennement cacheTime)
  });
}; 