import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import axios from 'axios'
import { toast } from 'sonner'
import { useAuthStore } from '../stores/authStore'

// Types pour les factures
export enum InvoiceStatus {
  Pending = 0,
  Paid = 1,
  Cancelled = 2
}

export enum PaymentMethod {
  CreditCard = 0,
  BankTransfer = 1,
  Cash = 2
}

export interface Invoice {
  id: number
  invoiceNumber: string
  mobileUserId: number
  cartId: number
  createdAt: string
  paidAt?: string
  totalAmount: number
  status: InvoiceStatus
  paymentMethod?: PaymentMethod
  paymentReference?: string
  billingAddress?: string
  notes?: string
  // Relations
  mobileUser?: {
    id: number
    firstName: string
    lastName: string
    email: string
  }
  cart?: {
    id: number
    items: any[]
  }
}

export interface CreateInvoiceDto {
  mobileUserId: number
  cartId: number
  totalAmount: number
  status: InvoiceStatus
  paymentMethod?: PaymentMethod
  paymentReference?: string
  billingAddress?: string
  notes?: string
}

export interface UpdateInvoiceDto {
  status?: InvoiceStatus
  paymentMethod?: PaymentMethod
  paymentReference?: string
  billingAddress?: string
  notes?: string
  paidAt?: string
}

// API Base URL
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5094/api'

// Essayer les deux variantes d'URL pour les factures
const INVOICE_ENDPOINTS = [
  `${API_BASE_URL}/invoices`,  // pluriel
  `${API_BASE_URL}/invoice`,   // singulier
]

// Hook pour récupérer toutes les factures
export const useInvoices = () => {
  const token = useAuthStore((state) => state.token)
  
  return useQuery({
    queryKey: ['invoices'],
    queryFn: async () => {
      console.log('Fetching all invoices with token:', token)
      
      // Essayer d'abord avec authentification sur le premier endpoint (pluriel)
      try {
        console.log('Tentative avec URL et authentification:', INVOICE_ENDPOINTS[0])
        const response = await axios.get(INVOICE_ENDPOINTS[0], {
          headers: {
            Authorization: `Bearer ${token}`
          }
        })
        console.log('Invoices response:', response.data)
        return response.data
      } catch (firstError: any) {
        console.warn(`Erreur avec l'URL ${INVOICE_ENDPOINTS[0]} (authentifié):`, firstError.message)
        
        // Essayer sans authentification (pour tester si c'est un problème d'autorisations)
        try {
          console.log('Tentative sans authentification:', INVOICE_ENDPOINTS[0])
          const response = await axios.get(INVOICE_ENDPOINTS[0])
          console.log('Invoices response (sans auth):', response.data)
          return response.data
        } catch (authError: any) {
          console.warn(`Échec sans authentification pour ${INVOICE_ENDPOINTS[0]}:`, authError.message)
        }
        
        // Essayer le deuxième endpoint (singulier) avec authentification
        try {
          console.log('Tentative avec URL alternative:', INVOICE_ENDPOINTS[1])
          const response = await axios.get(INVOICE_ENDPOINTS[1], {
            headers: {
              Authorization: `Bearer ${token}`
            }
          })
          console.log('Invoices response (alternative):', response.data)
          return response.data
        } catch (secondError: any) {
          console.error('Tous les endpoints ont échoué:')
          console.error(`- ${INVOICE_ENDPOINTS[0]} (auth): ${firstError.message}`)
          console.error(`- ${INVOICE_ENDPOINTS[1]} (auth): ${secondError.message}`)
          
          if (secondError.response) {
            console.error('Détails de la dernière erreur:', {
              status: secondError.response.status,
              data: secondError.response.data,
              headers: secondError.response.headers
            })
          }
          
          throw new Error('Impossible de récupérer les factures avec les URLs connues')
        }
      }
    },
    retry: 0,
    refetchOnWindowFocus: false
  })
}

// Hook pour récupérer une facture par son ID
export const useInvoice = (id: number) => {
  const token = useAuthStore((state) => state.token)
  
  return useQuery({
    queryKey: ['invoices', id],
    queryFn: async () => {
      console.log(`Fetching invoice ${id} with token:`, token)
      try {
        const response = await axios.get(`${API_BASE_URL}/invoices/${id}`, {
          headers: {
            Authorization: `Bearer ${token}`
          }
        })
        console.log(`Invoice ${id} response:`, response.data)
        return response.data
      } catch (error: any) {
        console.error(`Error fetching invoice ${id}:`, error)
        if (error.response) {
          console.error('Error details:', {
            status: error.response.status,
            data: error.response.data,
            headers: error.response.headers
          })
        }
        throw error
      }
    },
    enabled: !!id && !!token
  })
}

// Hook pour créer une nouvelle facture
export const useCreateInvoice = () => {
  const queryClient = useQueryClient()
  const token = useAuthStore((state) => state.token)
  
  return useMutation({
    mutationFn: async (invoice: CreateInvoiceDto) => {
      console.log('Creating new invoice:', invoice)
      const response = await axios.post(`${API_BASE_URL}/invoices`, invoice, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })
      return response.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['invoices'] })
    },
    onError: (error: any) => {
      console.error('Error creating invoice:', error)
      toast.error(`Erreur lors de la création de la facture: ${error.message}`)
    }
  })
}

// Hook pour mettre à jour une facture
export const useUpdateInvoice = () => {
  const queryClient = useQueryClient()
  const token = useAuthStore((state) => state.token)
  
  return useMutation({
    mutationFn: async ({ id, invoice }: { id: number, invoice: UpdateInvoiceDto }) => {
      console.log(`Updating invoice ${id} with:`, invoice)
      const response = await axios.put(`${API_BASE_URL}/invoices/${id}`, invoice, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })
      return response.data
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['invoices'] })
      queryClient.invalidateQueries({ queryKey: ['invoices', variables.id] })
    },
    onError: (error: any) => {
      console.error('Error updating invoice:', error)
      toast.error(`Erreur lors de la mise à jour de la facture: ${error.message}`)
    }
  })
}

// Hook pour supprimer une facture
export const useDeleteInvoice = () => {
  const queryClient = useQueryClient()
  const token = useAuthStore((state) => state.token)
  
  return useMutation({
    mutationFn: async (id: number) => {
      console.log(`Deleting invoice ${id}`)
      const response = await axios.delete(`${API_BASE_URL}/invoices/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })
      return response.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['invoices'] })
    },
    onError: (error: any) => {
      console.error('Error deleting invoice:', error)
      toast.error(`Erreur lors de la suppression de la facture: ${error.message}`)
    }
  })
}

// Hook pour marquer une facture comme payée
export const useMarkInvoiceAsPaid = () => {
  const queryClient = useQueryClient()
  const token = useAuthStore((state) => state.token)
  
  return useMutation({
    mutationFn: async ({ id, paymentMethod, paymentReference }: { id: number, paymentMethod: PaymentMethod, paymentReference?: string }) => {
      console.log(`Marking invoice ${id} as paid`)
      const response = await axios.put(`${API_BASE_URL}/invoices/${id}/pay`, {
        paymentMethod,
        paymentReference
      }, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })
      return response.data
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['invoices'] })
      queryClient.invalidateQueries({ queryKey: ['invoices', variables.id] })
    },
    onError: (error: any) => {
      console.error('Error marking invoice as paid:', error)
      toast.error(`Erreur lors du paiement de la facture: ${error.message}`)
    }
  })
}

// Hook pour annuler une facture
export const useCancelInvoice = () => {
  const queryClient = useQueryClient()
  const token = useAuthStore((state) => state.token)
  
  return useMutation({
    mutationFn: async (id: number) => {
      console.log(`Cancelling invoice ${id}`)
      const response = await axios.put(`${API_BASE_URL}/invoices/${id}/cancel`, {}, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })
      return response.data
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['invoices'] })
      queryClient.invalidateQueries({ queryKey: ['invoices', variables] })
    },
    onError: (error: any) => {
      console.error('Error cancelling invoice:', error)
      toast.error(`Erreur lors de l'annulation de la facture: ${error.message}`)
    }
  })
} 