import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer, Cell } from 'recharts';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ChartContainer, ChartTooltip } from '@/components/ui/chart';
import { formatCurrency } from '@/services/kpiService';

interface RevenueChartProps {
  data: Array<{
    month: string;
    monthShort: string;
    revenue: number;
  }>;
  isLoading?: boolean;
}

// Type étendu pour les données du graphique
interface ChartDataItem {
  month: string;
  monthShort: string;
  revenue: number;
  isCurrentMonth?: boolean;
}

export const RevenueChart: React.FC<RevenueChartProps> = ({ 
  data = [], 
  isLoading = false 
}) => {
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

  // Forcer la conversion des revenus en nombres
  const numericData = data.map(item => ({
    ...item,
    revenue: parseFloat(Number(item.revenue).toFixed(2))
  }));
  
  // Identifier le mois courant (dernier mois dans la liste)
  const currentMonth = numericData.length > 0 ? numericData[numericData.length - 1] : null;
  
  // Vérifier si les données contiennent des valeurs non nulles
  const monthsWithRevenue = numericData.filter(item => item.revenue > 0);
  const hasNonZeroData = monthsWithRevenue.length > 0;
  
  // Préparation des données pour l'affichage
  let chartData: ChartDataItem[] = [];
  
  // Si nous avons des données réelles
  if (numericData.length > 0) {
    // Marquer le mois courant (dernier mois)
    chartData = numericData.map(item => {
      const isCurrentMonth = item === currentMonth;
      return {
        ...item,
        isCurrentMonth
      };
    });
  } 
  // Si aucune donnée n'est disponible, afficher un exemple
  else {
    // Rechercher le mois actuel
    const currentDate = new Date();
    const currentMonthName = new Intl.DateTimeFormat('fr-FR', { month: 'long' }).format(currentDate);
    const currentMonthShort = currentMonthName.substring(0, 3);
    const currentYear = currentDate.getFullYear();
    
    // Créer un ensemble de données factices pour montrer l'exemple
    chartData = [
      { month: "Exemple - Pas de données", monthShort: "Ex.", revenue: 0 },
      { 
        month: `${currentMonthName} ${currentYear}`, 
        monthShort: currentMonthShort,
        revenue: 1000, // Valeur factice pour l'exemple
        isCurrentMonth: true
      },
      { month: "Données futures attendues", monthShort: "Fut.", revenue: 0 }
    ];
  }
  
  // Détecter si nous affichons des données d'exemple
  const isExampleData = chartData[0]?.month?.includes("Exemple") || false;
  
  // Calculer le total des revenus pour l'afficher
  const totalRevenue = monthsWithRevenue.reduce((sum, item) => sum + item.revenue, 0);
  
  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle>Revenus mensuels</CardTitle>
        <CardDescription>
          Évolution du chiffre d'affaires sur les 7 derniers mois
          {hasNonZeroData && ` · Total : ${formatCurrency(totalRevenue)}`}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[300px]">
          {isExampleData && (
            <div className="mb-4 text-sm text-amber-600">
              <p>Note : Aucun revenu enregistré pour le moment. Graphique d'exemple affiché ci-dessous.</p>
            </div>
          )}
          
          <ChartContainer>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart 
                data={chartData} 
                margin={{ top: 10, right: 30, left: 30, bottom: 25 }}
              >
                <CartesianGrid 
                  strokeDasharray="3 3" 
                  vertical={false} 
                />
                <XAxis 
                  dataKey="monthShort" 
                  tick={{ fontSize: 12 }}
                />
                <YAxis 
                  tick={{ fontSize: 12 }}
                  tickFormatter={(value) => value === 0 ? "0" : `${value / 1000}k€`}
                  domain={[0, 'auto']}
                />
                <Bar 
                  dataKey="revenue" 
                  name="Revenus"
                  radius={[4, 4, 0, 0]}
                  isAnimationActive={true}
                >
                  {chartData.map((entry, index) => (
                    <Cell 
                      key={`cell-${index}`} 
                      fill={entry.isCurrentMonth ? '#3b82f6' : '#93c5fd'} 
                    />
                  ))}
                </Bar>
                <ChartTooltip
                  content={({ active, payload }) => {
                    if (active && payload && payload.length) {
                      const month = payload[0].payload.month;
                      const revenue = formatCurrency(payload[0].value as number);
                      
                      return (
                        <div className="bg-white p-2 border rounded shadow-sm">
                          <p className="font-medium">{month}</p>
                          <p>CA : {revenue}</p>
                          {isExampleData && <p className="text-xs text-amber-600">(Données d'exemple)</p>}
                        </div>
                      );
                    }
                    return null;
                  }}
                />
              </BarChart>
            </ResponsiveContainer>
          </ChartContainer>
        </div>
      </CardContent>
    </Card>
  );
}; 