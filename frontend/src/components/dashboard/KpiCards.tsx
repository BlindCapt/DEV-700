import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, ShoppingBag, Package, AlertTriangle, TrendingUp } from "lucide-react";
import { formatCurrency } from "@/services/kpiService";

// Interface pour les props du composant
interface KpiCardsProps {
  totalRevenue: number | null;
  totalOrders: number | null;
  averageOrderValue: number | null;
  lowStockProducts: number | null;
  activeUsers: number | null;
  isLoading?: boolean;
}

export function KpiCards({
  totalRevenue,
  totalOrders,
  averageOrderValue,
  lowStockProducts,
  activeUsers,
  isLoading = false,
}: KpiCardsProps) {
  // Fonction pour afficher une valeur ou "N/A" si elle est nulle
  const formatValue = (value: number | null): string => {
    return value === null || value === undefined ? "N/A" : String(value);
  };

  // Fonction pour formater les valeurs monétaires ou "N/A" si elles sont nulles
  const formatMonetaryValue = (value: number | null): string => {
    return value === null || value === undefined ? "N/A" : formatCurrency(value);
  };

  // Fonction pour déterminer la couleur du texte des produits à faible stock
  const getLowStockTextColor = (value: number | null): string => {
    if (value === null || value === undefined) return "";
    return value > 0 ? "text-red-600" : "";
  };

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-5">
      {/* Carte Chiffre d'affaires */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Chiffre d'affaires</CardTitle>
          <TrendingUp className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="h-6 w-3/4 animate-pulse rounded bg-muted"></div>
          ) : (
            <div className="text-2xl font-bold">{formatMonetaryValue(totalRevenue)}</div>
          )}
          <p className="text-xs text-muted-foreground">Total des ventes réalisées</p>
        </CardContent>
      </Card>

      {/* Carte Commandes */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Commandes</CardTitle>
          <ShoppingBag className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="h-6 w-1/3 animate-pulse rounded bg-muted"></div>
          ) : (
            <div className="text-2xl font-bold">{formatValue(totalOrders)}</div>
          )}
          <p className="text-xs text-muted-foreground">Nombre total de commandes</p>
        </CardContent>
      </Card>

      {/* Carte Panier moyen */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Panier moyen</CardTitle>
          <ShoppingBag className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="h-6 w-2/4 animate-pulse rounded bg-muted"></div>
          ) : (
            <div className="text-2xl font-bold">{formatMonetaryValue(averageOrderValue)}</div>
          )}
          <p className="text-xs text-muted-foreground">Valeur moyenne des commandes</p>
        </CardContent>
      </Card>

      {/* Carte Produits en alerte */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Stock faible</CardTitle>
          <AlertTriangle className={`h-4 w-4 ${lowStockProducts && lowStockProducts > 0 ? 'text-red-600' : 'text-muted-foreground'}`} />
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="h-6 w-1/4 animate-pulse rounded bg-muted"></div>
          ) : (
            <div className={`text-2xl font-bold ${getLowStockTextColor(lowStockProducts)}`}>{formatValue(lowStockProducts)}</div>
          )}
          <p className="text-xs text-muted-foreground">Produits à réapprovisionner</p>
        </CardContent>
      </Card>

      {/* Carte Utilisateurs actifs */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Utilisateurs</CardTitle>
          <Users className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="h-6 w-1/3 animate-pulse rounded bg-muted"></div>
          ) : (
            <div className="text-2xl font-bold">{formatValue(activeUsers)}</div>
          )}
          <p className="text-xs text-muted-foreground">Utilisateurs actifs</p>
        </CardContent>
      </Card>
    </div>
  );
} 