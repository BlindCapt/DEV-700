import * as React from 'react'
import axios from 'axios'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import { Trash2 } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'

interface DeleteProductDialogProps {
  productId: number
  productName: string
}

export function DeleteProductDialog({ productId, productName }: DeleteProductDialogProps) {
  const [open, setOpen] = React.useState(false)
  const queryClient = useQueryClient()

  const handleDelete = async () => {
    try {
      await axios.delete(`http://localhost:5094/api/products/${productId}`)
      queryClient.invalidateQueries({ queryKey: ['products'] })
      setOpen(false)
    } catch (error) {
      console.error('Erreur lors de la suppression du produit:', error)
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="outline" size="sm">
          <Trash2 className="mr-2 h-4 w-4" /> Supprimer
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Confirmer la suppression</DialogTitle>
          <DialogDescription>
            Êtes-vous sûr de vouloir supprimer le produit "{productName}" ?
            Cette action est irréversible.
          </DialogDescription>
        </DialogHeader>
        <div className="flex justify-end space-x-2">
          <Button
            variant="outline"
            onClick={() => setOpen(false)}
          >
            Annuler
          </Button>
          <Button
            variant="destructive"
            onClick={handleDelete}
          >
            Supprimer
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
} 