// import * as React from 'react'
import { useState, useMemo } from 'react'
import { useProducts } from '../api/useProducts'
import { ProductTable } from '../components/ProductTable.tsx'
import { Input } from '@/components/ui/input'
import { AddProductDialog } from '../components/AddProductDialog'
import { BulkImportDialog } from '../components/BulkImportDialog'

export default function Products() {
  const { data: products } = useProducts()
  const [searchTerm, setSearchTerm] = useState('')

  const filteredProducts = useMemo(() => {
    if (!products) return []
    return products.filter(product => 
      product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      product.category.toLowerCase().includes(searchTerm.toLowerCase())
    )
  }, [products, searchTerm])

  return (
    <div className="p-8">
      <div className="space-y-4">
        <div className="flex justify-between">
          <Input
            placeholder="Rechercher un produit..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="max-w-sm"
          />
          <div className="space-x-2">
            <BulkImportDialog />
            <AddProductDialog />
          </div>
        </div>
        <div className="w-full min-w-full">
          <ProductTable products={filteredProducts || []} />
        </div>
      </div>
    </div>
  )
}