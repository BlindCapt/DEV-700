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
import { Plus } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const formSchema = z.object({
  barcode: z.string().min(1, 'Le code-barres est requis'),
  quantity: z.coerce.number().min(1, 'La quantité doit être supérieure à 0'),
  price: z.coerce.number().min(0, 'Le prix ne peut pas être négatif'),
})

export function AddProductDialog() {
  const [open, setOpen] = React.useState(false)
  const queryClient = useQueryClient()
  
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      barcode: '',
      quantity: 1,
      price: 0,
    },
  })

  const onSubmit = async (data: z.infer<typeof formSchema>) => {
    try {
      await axios.post('http://localhost:5094/api/products', {
        barcode: data.barcode,
        quantity: data.quantity,
        price: data.price,
      })
      
      // Invalider le cache pour recharger les produits
      queryClient.invalidateQueries({ queryKey: ['products'] })
      
      // Fermer la popup et réinitialiser le form
      setOpen(false)
      form.reset()
    } catch (error) {
      console.error('Erreur lors de l\'ajout du produit:', error)
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
          <Plus className="mr-2 h-4 w-4" /> Ajouter un produit
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Ajouter un produit</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="barcode"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Code-barres</FormLabel>
                  <FormControl>
                    <Input placeholder="Entrez le code-barres..." {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="quantity"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Quantité</FormLabel>
                  <FormControl>
                    <Input 
                      type="number" 
                      min="1" 
                      {...field}
                      onChange={e => field.onChange(e.target.valueAsNumber)}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
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
            <Button type="submit">Ajouter</Button>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
} 