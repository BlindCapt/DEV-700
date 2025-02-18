import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Edit, Trash2, ArrowUpDown } from 'lucide-react'
import { EditProductDialog } from './EditProductDialog'
import { DeleteProductDialog } from './DeleteProductDialog'
import { useState } from 'react'

interface Product {
  id: number
  name: string
  brand: string
  category: string
  imageUrl: string
  barcode: string
  price: number
  quantity: number
  threshold: number
}

type SortDirection = 'asc' | 'desc' | null

export const ProductTable = ({ products }: { products: Product[] }) => {
  const [sortDirection, setSortDirection] = useState<SortDirection>(null)

  const sortedProducts = [...products].sort((a, b) => {
    if (sortDirection === 'asc') {
      return a.price - b.price
    }
    if (sortDirection === 'desc') {
      return b.price - a.price
    }
    return 0
  })

  const toggleSort = () => {
    if (sortDirection === null) setSortDirection('asc')
    else if (sortDirection === 'asc') setSortDirection('desc')
    else setSortDirection(null)
  }

  return (
    <div className="w-full overflow-auto">
      <Table className="min-w-full table-fixed">
        <TableHeader>
          <TableRow>
            <TableHead className="w-[25%]">Nom</TableHead>
            <TableHead className="w-[25%]">Catégorie</TableHead>
            <TableHead 
              className="w-[10%] cursor-pointer"
              onClick={toggleSort}
            >
              <div className="flex items-center gap-2">
                Prix
                <ArrowUpDown className={`h-4 w-4 ${
                  sortDirection === 'asc' ? 'rotate-180' : ''
                }`} />
              </div>
            </TableHead>
            <TableHead className="w-[10%]">Stock</TableHead>
            <TableHead className="w-[30%]">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody className="w-full">
          {sortedProducts.map((product) => (
            <TableRow key={product.id}>
              <TableCell className="w-[25%] truncate">{product.name}</TableCell>
              <TableCell className="w-[25%] truncate">{product.category}</TableCell>
              <TableCell className="w-[10%]">{product.price}€</TableCell>
              <TableCell 
                className={`w-[10%] font-medium ${
                  product.quantity <= product.threshold 
                    ? "text-red-600" 
                    : ""
                }`}
              >
                {product.quantity}
              </TableCell>
              <TableCell className="w-[30%]">
                <div className="flex space-x-2">
                  <EditProductDialog product={product} />
                  <DeleteProductDialog 
                    productId={product.id} 
                    productName={product.name}
                  />
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}