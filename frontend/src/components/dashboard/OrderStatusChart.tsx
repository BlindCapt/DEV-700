import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ChartContainer, ChartTooltip } from '@/components/ui/chart';

interface OrderStatusChartProps {
  data: Array<{
    status: string;
    value: number;
  }>;
  isLoading?: boolean;
}

// Traduire les statuts des commandes en français
const translateStatus = (status: string): string => {
  switch (status.toLowerCase()) {
    case 'completed':
      return 'Terminée';
    case 'processing':
      return 'En cours';
    case 'pending':
      return 'En attente';
    case 'cancelled':
      return 'Annulée';
    case 'refunded':
      return 'Remboursée';
    case 'paid':
      return 'Payée';
    default:
      return status;
  }
};

export const OrderStatusChart: React.FC<OrderStatusChartProps> = ({ 
  data = [], 
  isLoading = false 
}) => {
  // Configuration des couleurs pour chaque statut
  const statusColors: Record<string, string> = {
    'completed': '#10b981', // vert
    'processing': '#3b82f6', // bleu
    'pending': '#f59e0b', // orange
    'cancelled': '#ef4444', // rouge
    'refunded': '#8b5cf6', // violet
    'paid': '#22c55e' // vert vif pour les commandes payées
  };

  // Calculer le total des commandes pour le pourcentage
  const total = data.reduce((sum, item) => sum + item.value, 0);

  // Préparer les données avec les traductions et calcul du total
  const preparedData = data.map(item => ({
    ...item,
    name: translateStatus(item.status),
    fill: statusColors[item.status.toLowerCase()] || '#6b7280', // gris par défaut
    percentage: total > 0 ? (item.value / total) * 100 : 0
  }));

  // Filtrer les données pour le graphique
  // Solution: Ne conserver que les données non nulles pour le rendu du graphique
  // Cela éliminera automatiquement les labels et les lignes des valeurs nulles
  const filteredData = preparedData.filter(item => item.value > 0);
  
  // Pour afficher le graphique même sans données, créons un jeu de données fictif si nécessaire
  const displayData = filteredData.length > 0 ? filteredData : [];
  const hasNoData = filteredData.length === 0;

  if (isLoading) {
    return (
      <Card className="w-full h-[400px]">
        <CardHeader>
          <div className="h-6 w-2/3 bg-gray-200 animate-pulse rounded"></div>
          <div className="h-4 w-1/2 bg-gray-200 animate-pulse rounded"></div>
        </CardHeader>
        <CardContent className="h-[290px]">
          <div className="h-full w-full bg-gray-100 animate-pulse rounded"></div>
        </CardContent>
      </Card>
    );
  }

  // Fonction personnalisée pour les labels avec un meilleur positionnement
  const renderCustomizedLabel = (props: any) => {
    const { cx, cy, midAngle, outerRadius, name, percent } = props;
    
    // Calcul de la position du label
    const radian = Math.PI / 180;
    const radius = outerRadius + 25; // Distance du label par rapport au graphique (augmentée)
    const x = cx + radius * Math.cos(-midAngle * radian);
    const y = cy + radius * Math.sin(-midAngle * radian);
    
    // Pour les petits pourcentages, afficher seulement le nom
    if (percent < 0.05) {
      return (
        <text 
          x={x} 
          y={y} 
          fill="#FFFFFF" // Blanc
          stroke="#000000" // Contour noir pour meilleure visibilité
          strokeWidth={0.5} // Épaisseur fine pour le contour
          textAnchor={x > cx ? 'start' : 'end'} 
          dominantBaseline="central"
          fontSize={11}
          fontWeight="bold" // Police en gras pour meilleure lisibilité
        >
          {name}
        </text>
      );
    }
    
    return (
      <text 
        x={x} 
        y={y} 
        fill="#FFFFFF" // Blanc
        stroke="#000000" // Contour noir pour meilleure visibilité
        strokeWidth={0.5} // Épaisseur fine pour le contour
        textAnchor={x > cx ? 'start' : 'end'} 
        dominantBaseline="central"
        fontWeight="bold" // Police en gras pour meilleure lisibilité
      >
        {`${name} (${(percent * 100).toFixed(0)}%)`}
      </text>
    );
  };

  // Fonction personnalisée pour les lignes de label
  const renderLabelLine = (props: any) => {
    const { cx, cy, midAngle, outerRadius } = props;
    
    const radian = Math.PI / 180;
    const startRadius = outerRadius;
    const endRadius = outerRadius + 15; // Longueur du trait (ne va pas jusqu'au label)
    
    const start = {
      x: cx + startRadius * Math.cos(-midAngle * radian),
      y: cy + startRadius * Math.sin(-midAngle * radian)
    };
    
    const end = {
      x: cx + endRadius * Math.cos(-midAngle * radian),
      y: cy + endRadius * Math.sin(-midAngle * radian)
    };
    
    return <line x1={start.x} y1={start.y} x2={end.x} y2={end.y} stroke="#999" strokeWidth={1} />;
  };

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle>Statut des commandes</CardTitle>
        <CardDescription>Répartition des commandes par statut</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[300px] relative">
          <ChartContainer>
            {hasNoData ? (
              <div className="absolute inset-0 flex items-center justify-center text-gray-500">
                Aucune commande à afficher
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                  <Pie
                    data={displayData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={2}
                    dataKey="value"
                    nameKey="name"
                    label={renderCustomizedLabel}
                    labelLine={renderLabelLine}
                  >
                    {displayData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.fill} />
                    ))}
                  </Pie>
                  <ChartTooltip
                    content={({ active, payload }) => {
                      if (active && payload && payload.length) {
                        const data = payload[0].payload;
                        const percentage = ((data.value / total) * 100).toFixed(1);
                        
                        return (
                          <div className="bg-white p-2 border rounded shadow-sm">
                            <p className="font-medium">{data.name}</p>
                            <p>{data.value} commandes ({percentage}%)</p>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            )}
          </ChartContainer>
        </div>
      </CardContent>
    </Card>
  );
}; 