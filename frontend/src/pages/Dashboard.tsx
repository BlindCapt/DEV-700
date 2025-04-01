import React from 'react';
import { useKpiData } from '@/services/kpiService';
import { KpiCards } from '@/components/dashboard/KpiCards';
import { RevenueChart } from '@/components/dashboard/RevenueChart';
import { OrderStatusChart } from '@/components/dashboard/OrderStatusChart';
import { TopProductsChart } from '@/components/dashboard/TopProductsChart';
import { AlertCircle, RefreshCw } from 'lucide-react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';

export const Dashboard = () => {
  // Récupération des données KPI depuis l'API
  const { data, isLoading, error, isError, refetch, isFetching } = useKpiData();
  
  // État pour suivre les appels API déjà effectués
  const [initialFetchDone, setInitialFetchDone] = React.useState(false);
  const [lastUpdate, setLastUpdate] = React.useState<Date | null>(null);

  // Forcer le rafraîchissement des données seulement au premier montage
  React.useEffect(() => {
    if (!initialFetchDone) {
      console.log("Dashboard - Montage initial, rafraîchissement forcé des données");
      
      // Notification d'initialisation
      toast.info("Chargement des données du tableau de bord...", {
        description: "Récupération des dernières informations depuis l'API",
        icon: <RefreshCw className="h-4 w-4 animate-spin" />,
        closeButton: true, // Ajouter une croix pour fermer
        id: "initial-loading"
      });
      
      // Marquer comme effectué avant de lancer la requête
      setInitialFetchDone(true);
      
      // Déclencher le chargement des données
      refetch();
    }
  }, [initialFetchDone, refetch]);

  // Effet unique pour gérer les données chargées et les états de l'UI
  React.useEffect(() => {
    // Cas de chargement réussi avec des données
    if (data && !isFetching && initialFetchDone) {
      console.log("Dashboard - Données KPI chargées:", data);
      
      // Vérifier les données de revenus (logging uniquement pour debug)
      if (data.charts && data.charts.revenueByMonth) {
        console.log("Dashboard - Données revenus mensuels:", data.charts.revenueByMonth);
        
        const monthsWithRevenue = data.charts.revenueByMonth.filter(month => 
          month.revenue && Number(month.revenue) > 0
        );
        
        console.log("Dashboard - Mois avec des revenus:", monthsWithRevenue);
        console.log("Dashboard - Type de données revenue:", 
          data.charts.revenueByMonth.length > 0 
            ? typeof data.charts.revenueByMonth[0].revenue 
            : "pas de données"
        );
      }
      
      // Succès: Notification de mise à jour réussie
      toast.success("Données mises à jour", {
        description: `Dernière mise à jour à ${new Date().toLocaleTimeString()}`,
        duration: 3000,
        closeButton: true, // Ajouter une croix pour fermer
        id: "success-update" // ID unique pour remplacer les toasts précédents
      });
      
      // Mémoriser l'heure de la dernière mise à jour
      setLastUpdate(new Date());
    }
    
    // Cas d'erreur
    if (isError && error && initialFetchDone) {
      const errorMessage = error instanceof Error 
        ? error.message 
        : "Erreur inconnue lors du chargement des données";
        
      toast.error("Impossible de charger les données", {
        description: `${errorMessage}. Les données affichées pourraient être incomplètes.`,
        duration: 5000,
        closeButton: true, // Ajouter une croix pour fermer
        id: "error-toast" // ID unique pour éviter les duplications
      });
    }
    
    // Cas de chargement en cours
    if (isFetching && initialFetchDone) {
      toast.loading("Mise à jour en cours", {
        description: "Les données du tableau de bord sont en cours d'actualisation...",
        closeButton: true, // Ajouter une croix pour fermer
        id: "loading-toast" // ID pour pouvoir le remplacer ensuite
      });
    }
  }, [data, isError, error, isFetching, initialFetchDone]);

  // Gestion du rafraîchissement manuel
  const handleRefresh = async () => {
    console.log("Dashboard - Rafraîchissement manuel déclenché");
    toast.info("Rafraîchissement manuel...", {
      description: "Récupération des dernières données depuis l'API",
      icon: <RefreshCw className="h-4 w-4 animate-spin" />,
      closeButton: true, // Ajouter une croix pour fermer
      id: "manual-refresh" // ID unique
    });
    
    try {
      await refetch();
    } catch (refreshError) {
      console.error("Erreur lors du rafraîchissement manuel:", refreshError);
      toast.error("Échec du rafraîchissement", {
        description: "Impossible de récupérer les dernières données. Veuillez réessayer.",
        closeButton: true, // Ajouter une croix pour fermer
        id: "refresh-error" // ID unique
      });
    }
  };

  return (
    <div className="p-6 space-y-6 max-w-[98%] mx-auto">
      <div className="flex flex-row justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Tableau de bord</h1>
        
        <Button 
          variant="outline" 
          size="sm" 
          onClick={handleRefresh} 
          disabled={isLoading || isFetching}
          className="flex items-center gap-2"
        >
          <RefreshCw className={`h-4 w-4 ${isFetching ? 'animate-spin' : ''}`} />
          <span>Actualiser</span>
        </Button>
      </div>
      
      {/* Affichage des erreurs graves uniquement avec une alerte persistante */}
      {isError && (
        <Alert variant="destructive" className="mb-6">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Impossible de charger les données</AlertTitle>
          <AlertDescription>
            {error instanceof Error ? error.message : "Erreur inconnue lors du chargement des données"}. Les données affichées pourraient être incomplètes ou indisponibles.
          </AlertDescription>
        </Alert>
      )}

      {/* Cartes KPI - toujours affichées, mais avec des valeurs null en cas d'erreur */}
      <KpiCards
        totalRevenue={isError ? null : data?.kpis?.totalRevenue ?? null}
        totalOrders={isError ? null : data?.kpis?.totalOrders ?? null}
        averageOrderValue={isError ? null : data?.kpis?.averageOrderValue ?? null}
        lowStockProducts={isError ? null : data?.kpis?.lowStockProducts ?? null}
        activeUsers={isError ? null : data?.kpis?.activeUsers ?? null}
        isLoading={isLoading}
      />

      {/* Graphiques - affichés uniquement si pas d'erreur ou si des données sont disponibles */}
      {(!isError || (data && data.charts)) && (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5 mt-6">
            {/* Graphique des revenus */}
            <RevenueChart 
              data={data?.charts?.revenueByMonth || []} 
              isLoading={isLoading} 
            />
            
            {/* Graphique des commandes par statut */}
            <OrderStatusChart 
              data={data?.charts?.ordersByStatus || []} 
              isLoading={isLoading} 
            />
          </div>
          
          {/* Graphique des produits les plus vendus */}
          <div className="mt-6">
            <TopProductsChart 
              data={data?.charts?.topSellingProducts || []} 
              isLoading={isLoading}
            />
          </div>
        </>
      )}
    </div>
  );
}; 