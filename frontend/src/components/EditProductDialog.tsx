import * as React from 'react'
import { useForm } from 'react-hook-form'
import axios from 'axios'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Edit } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { useState } from 'react'
import { useToast } from "@/hooks/use-toast"

const formSchema = z.object({
  price: z.coerce.number().min(0, 'Le prix ne peut pas être négatif'),
  quantity: z.coerce.number().min(0, 'La quantité ne peut pas être négative'),
  threshold: z.coerce.number().min(0, 'Le seuil ne peut pas être négatif'),
})

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

interface EditProductDialogProps {
  product: Product
}

export function EditProductDialog({ product }: EditProductDialogProps) {
  const [open, setOpen] = React.useState(false)
  const queryClient = useQueryClient()
  const [isOrdering, setIsOrdering] = useState(false)
  const [orderQuantity, setOrderQuantity] = useState('')
  
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      price: product.price || 0,
      threshold: product.threshold || 0,
    },
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const values = form.getValues();
    try {
      console.log('Submitting data:', values);
      await axios.put(`http://localhost:5094/api/products/${product.id}`, {
        ...product,
        price: values.price,
        threshold: values.threshold,
      });
      
      queryClient.invalidateQueries({ queryKey: ['products'] });
      setOpen(false);
    } catch (error) {
      console.error('Erreur lors de la modification du produit:', error);
    }
  };

  const handleOrder = async () => {
    try {
      await axios.put(`http://localhost:5094/api/products/${product.id}/stock`, {
        quantityToAdd: Number(orderQuantity)
      })
      
      queryClient.invalidateQueries({ queryKey: ['products'] })
      setIsOrdering(false)
      setOrderQuantity('')
    } catch (error) {
      console.error('Erreur lors de la commande:', error)
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="outline" size="sm">
          <Edit className="mr-2 h-4 w-4" /> Modifier
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[850px]">
        <DialogHeader>
          <DialogTitle>Modifier le produit</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="flex gap-8">
              <div className="flex-1 flex flex-col gap-4 py-4">
                <div id="first_row" className="flex gap-4">
                  {product.imageUrl && (
                    <div>
                      <img 
                        src={product.imageUrl} 
                        alt={product.name} 
                        className="w-32 h-32 object-cover rounded-lg"
                      />
                    </div>
                  )}
                  <div className='flex flex-col gap-2'>
                    <div className="grid gap-2">
                      <div className="text-m font-medium">Nom :</div>
                      <div className="font-medium">{product.name}</div>
                    </div>
                    <div className="grid gap-2">
                      <div className="text-m font-medium">Marque :</div>
                      <div className="font-medium">{product.brand}</div>
                    </div>
                  </div>
                </div>
                <div className="grid gap-2">
                  <div className="text-sm font-medium">Catégorie</div>
                  <div className="font-medium">{product.category}</div>
                </div>
                <div className="grid gap-2">
                  <div className="text-sm font-medium">Code-barres</div>
                  <div className="font-medium">{product.barcode}</div>
                </div>
                <FormField
                  control={form.control}
                  name="price"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Prix</FormLabel>
                      <FormControl>
                        <Input 
                          type="number" 
                          step="0.01" 
                          min="0" 
                          {...field}
                          onChange={e => field.onChange(e.target.valueAsNumber)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
              <div className="w-72 border-l pl-8 py-4">
                <div className="text-lg font-semibold mb-4">Gestion du stock</div>
                <div className="space-y-4">
                  <div className='flex gap-4 justify-between'>
                    <div className="grid gap-2">
                      <div className="text-sm font-medium">Stock actuel</div>
                      <div className="text-2xl font-bold">{product.quantity}</div>
                    </div>
                    {!isOrdering ? (
                    <Button 
                      variant="outline" 
                      onClick={() => setIsOrdering(true)}
                      className="w-1/2"
                    >
                      Recommander
                    </Button>
                    ) : (
                    <div className="space-y-2">
                      <Input
                        type="number"
                        placeholder="Quantité à commander"
                        value={orderQuantity}
                        onChange={(e) => setOrderQuantity(e.target.value)}
                      />
                      <div className="flex gap-2">
                        <Button 
                          variant="default"
                          onClick={handleOrder}
                          className="flex-1"
                        >
                          Commander
                        </Button>
                        <Button 
                          variant="outline"
                          onClick={() => {
                            setIsOrdering(false)
                            setOrderQuantity('')
                          }}
                          className="flex-1"
                        >
                          Annuler
                        </Button>
                      </div>
                    </div>
                    )}
                  </div>
                  <FormField
                    control={form.control}
                    name="threshold"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Seuil d'alerte</FormLabel>
                        <FormControl>
                          <Input 
                            type="number" 
                            min="0" 
                            {...field}
                            onChange={e => field.onChange(e.target.valueAsNumber)}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
              </div>
            </div>
            <div className="flex justify-end mt-6">
              <Button type="submit">
                Enregistrer les modifications
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
} 