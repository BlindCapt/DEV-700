import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer } from 'recharts';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ChartContainer, ChartTooltip } from '@/components/ui/chart';
import { formatCurrency } from '@/services/kpiService';

// Interface pour les propriétés du composant
interface TopProductsChartProps {
  data: Array<{
    product: string;
    quantity: number;
    revenue: number;
  }>;
  isLoading?: boolean;
}

export const TopProductsChart: React.FC<TopProductsChartProps> = ({ 
  data = [], 
  isLoading = false 
}) => {
  // Fonction pour formater les valeurs dans l'infobulle
  const formatTooltipValue = (value: number): string => {
    return formatCurrency(value);
  };

  // Fonction pour simplifier les noms de produits trop longs
  const shortenProductName = (name: string): string => {
    return name.length > 25 ? `${name.substring(0, 22)}...` : name;
  };

  // Trier les données par revenu en ordre décroissant
  const sortedData = [...data].sort((a, b) => b.revenue - a.revenue);

  // Vérifier si des données sont disponibles
  const hasData = sortedData && sortedData.length > 0;

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

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle>Produits les plus vendus</CardTitle>
        <CardDescription>
          Top {sortedData.length > 0 ? sortedData.length : 5} des produits par chiffre d'affaires
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[300px]">
          {!hasData ? (
            <div className="h-full w-full flex items-center justify-center text-muted-foreground">
              <p>Aucun produit vendu à afficher</p>
            </div>
          ) : (
            <ChartContainer>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart 
                  data={sortedData} 
                  margin={{ top: 10, right: 10, left: 10, bottom: 60 }}
                  layout="vertical"
                >
                  <CartesianGrid strokeDasharray="3 3" horizontal={true} vertical={false} />
                  <XAxis 
                    type="number" 
                    tick={{ fontSize: 12 }} 
                    tickFormatter={(value) => formatCurrency(value)} 
                  />
                  <YAxis 
                    type="category" 
                    dataKey="product" 
                    tick={{ fontSize: 12 }} 
                    width={150}
                    tickFormatter={shortenProductName}
                  />
                  <Bar 
                    dataKey="revenue" 
                    fill="#3498db" 
                    radius={[0, 4, 4, 0]} 
                    barSize={20}
                  />
                  <ChartTooltip 
                    content={({ active, payload }) => {
                      if (active && payload && payload.length) {
                        const product = payload[0].payload.product;
                        const revenue = formatTooltipValue(payload[0].value as number);
                        const quantity = payload[0].payload.quantity;
                        
                        return (
                          <div className="bg-white p-2 border rounded shadow-sm">
                            <p className="font-medium">{product}</p>
                            <p>CA: {revenue}</p>
                            <p>Quantité: {quantity} unités</p>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                </BarChart>
              </ResponsiveContainer>
            </ChartContainer>
          )}
        </div>
      </CardContent>
    </Card>
  );
}; 