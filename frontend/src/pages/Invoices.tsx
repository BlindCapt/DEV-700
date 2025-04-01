import { useState } from 'react'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "../components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../components/ui/dialog"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "../components/ui/dropdown-menu"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../components/ui/select"
import { Button } from "../components/ui/button"
import { Input } from "../components/ui/input"
import { Label } from "../components/ui/label"
import { Textarea } from "../components/ui/textarea"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../components/ui/tabs"
import { Badge } from "../components/ui/badge"
import { Loader2, MoreHorizontal, FileText, Eye, CheckCircle, XCircle, Plus, RefreshCw } from "lucide-react"
import { toast } from "sonner"
import {
  useInvoices,
  useInvoice,
  useCreateInvoice,
  useUpdateInvoice,
  useDeleteInvoice,
  useMarkInvoiceAsPaid,
  useCancelInvoice,
  Invoice,
  InvoiceStatus,
  PaymentMethod,
  CreateInvoiceDto,
  UpdateInvoiceDto
} from '../api/useInvoices'

export const Invoices = () => {
  // États pour gérer les modales
  const [isCreateInvoiceDialogOpen, setIsCreateInvoiceDialogOpen] = useState(false)
  const [isEditInvoiceDialogOpen, setIsEditInvoiceDialogOpen] = useState(false)
  const [isViewInvoiceDialogOpen, setIsViewInvoiceDialogOpen] = useState(false)
  const [isPayInvoiceDialogOpen, setIsPayInvoiceDialogOpen] = useState(false)
  const [isDeleteInvoiceDialogOpen, setIsDeleteInvoiceDialogOpen] = useState(false)
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null)
  
  // États pour les filtres et la recherche
  const [statusFilter, setStatusFilter] = useState<string>("all")
  const [searchQuery, setSearchQuery] = useState("")
  
  // États pour les formulaires
  const [newInvoice, setNewInvoice] = useState<CreateInvoiceDto>({
    mobileUserId: 0,
    cartId: 0,
    totalAmount: 0,
    status: InvoiceStatus.Pending,
  })
  
  const [editInvoice, setEditInvoice] = useState<UpdateInvoiceDto>({
    status: InvoiceStatus.Pending,
  })
  
  const [paymentInfo, setPaymentInfo] = useState({
    paymentMethod: PaymentMethod.CreditCard,
    paymentReference: ''
  })
  
  // Récupérer les données avec React Query
  const { data: invoices, isLoading, refetch, isFetching } = useInvoices()
  const { data: invoiceDetails, refetch: refetchInvoiceDetails } = useInvoice(selectedInvoice?.id || 0)
  
  // Mutations pour opérations CRUD
  const createInvoiceMutation = useCreateInvoice()
  const updateInvoiceMutation = useUpdateInvoice()
  const deleteInvoiceMutation = useDeleteInvoice()
  const markAsPaidMutation = useMarkInvoiceAsPaid()
  const cancelInvoiceMutation = useCancelInvoice()
  
  // Handler pour rafraîchir les données
  const handleRefresh = () => {
    refetch();
    toast.success("Données rafraîchies");
  };
  
  // Filtrer les factures
  const filteredInvoices = invoices ? invoices.filter((invoice: Invoice) => {
    // Filtre par statut
    if (statusFilter !== "all") {
      const statusValue = parseInt(statusFilter)
      if (invoice.status !== statusValue) {
        return false
      }
    }
    
    // Filtre par recherche (numéro de facture ou info client)
    if (searchQuery) {
      const query = searchQuery.toLowerCase()
      const invoiceNumber = invoice.invoiceNumber.toLowerCase()
      const clientName = invoice.mobileUser ? 
        `${invoice.mobileUser.firstName} ${invoice.mobileUser.lastName}`.toLowerCase() : ''
      const clientEmail = invoice.mobileUser ? invoice.mobileUser.email.toLowerCase() : ''
      
      return invoiceNumber.includes(query) || 
             clientName.includes(query) || 
             clientEmail.includes(query)
    }
    
    return true
  }) : []
  
  // Fonction pour formater les dates
  const formatDate = (dateString?: string) => {
    if (!dateString) return 'N/A'
    return format(new Date(dateString), 'dd MMM yyyy, HH:mm', { locale: fr })
  }
  
  // Fonction pour formater les montants
  const formatAmount = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' }).format(amount)
  }
  
  // Fonction pour obtenir le libellé du statut
  const getStatusLabel = (status: InvoiceStatus) => {
    switch(status) {
      case InvoiceStatus.Pending:
        return 'En attente'
      case InvoiceStatus.Paid:
        return 'Payée'
      case InvoiceStatus.Cancelled:
        return 'Annulée'
      case InvoiceStatus.Refunded:
        return 'Remboursée'
      default:
        return 'Inconnu'
    }
  }
  
  // Fonction pour obtenir le style du badge de statut
  const getStatusBadgeVariant = (status: InvoiceStatus) => {
    switch(status) {
      case InvoiceStatus.Pending:
        return 'secondary'
      case InvoiceStatus.Paid:
        return 'default'
      case InvoiceStatus.Cancelled:
        return 'destructive'
      case InvoiceStatus.Refunded:
        return 'warning'
      default:
        return 'outline'
    }
  }
  
  // Fonction pour obtenir le libellé de la méthode de paiement
  const getPaymentMethodLabel = (method?: PaymentMethod) => {
    if (method === undefined) return 'N/A'
    
    switch(method) {
      case PaymentMethod.CreditCard:
        return 'Carte de crédit'
      case PaymentMethod.BankTransfer:
        return 'Virement bancaire'
      case PaymentMethod.Cash:
        return 'Espèces'
      default:
        return 'Inconnu'
    }
  }
  
  // Handler pour voir les détails d'une facture
  const handleViewInvoice = (invoice: Invoice) => {
    setSelectedInvoice(invoice)
    refetchInvoiceDetails()
    setIsViewInvoiceDialogOpen(true)
  }
  
  // Handler pour éditer une facture
  const handleEditInvoice = (invoice: Invoice) => {
    setSelectedInvoice(invoice)
    setEditInvoice({
      status: invoice.status,
      billingAddress: invoice.billingAddress,
      notes: invoice.notes
    })
    setIsEditInvoiceDialogOpen(true)
  }
  
  // Handler pour ouvrir la boîte de dialogue de paiement
  const handleOpenPayDialog = (invoice: Invoice) => {
    setSelectedInvoice(invoice)
    setPaymentInfo({
      paymentMethod: PaymentMethod.CreditCard,
      paymentReference: ''
    })
    setIsPayInvoiceDialogOpen(true)
  }
  
  // Handler pour marquer une facture comme payée
  const handleMarkAsPaid = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedInvoice) return
    
    try {
      await markAsPaidMutation.mutateAsync({
        id: selectedInvoice.id,
        paymentMethod: paymentInfo.paymentMethod,
        paymentReference: paymentInfo.paymentReference
      })
      setIsPayInvoiceDialogOpen(false)
      toast.success('Facture marquée comme payée')
    } catch (error) {
      console.error('Erreur lors du paiement de la facture:', error)
    }
  }
  
  // Handler pour annuler une facture
  const handleCancelInvoice = async (invoice: Invoice) => {
    if (window.confirm(`Êtes-vous sûr de vouloir annuler la facture ${invoice.invoiceNumber} ?`)) {
      try {
        await cancelInvoiceMutation.mutateAsync(invoice.id)
        toast.success('Facture annulée avec succès')
      } catch (error) {
        console.error('Erreur lors de l\'annulation de la facture:', error)
      }
    }
  }
  
  // Handler pour supprimer une facture
  const handleDeleteInvoice = (invoice: Invoice) => {
    setSelectedInvoice(invoice)
    setIsDeleteInvoiceDialogOpen(true)
  }
  
  // Handler pour confirmer la suppression
  const handleConfirmDelete = async () => {
    if (!selectedInvoice) return
    
    try {
      await deleteInvoiceMutation.mutateAsync(selectedInvoice.id)
      setIsDeleteInvoiceDialogOpen(false)
      toast.success('Facture supprimée avec succès')
    } catch (error) {
      console.error('Erreur lors de la suppression de la facture:', error)
    }
  }
  
  // Handler pour le changement de statut lors de l'édition
  const handleEditStatusChange = (value: string) => {
    setEditInvoice({
      ...editInvoice,
      status: parseInt(value) as InvoiceStatus
    })
  }
  
  // Handler pour soumettre les modifications
  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedInvoice) return
    
    try {
      await updateInvoiceMutation.mutateAsync({
        id: selectedInvoice.id,
        invoice: editInvoice
      })
      setIsEditInvoiceDialogOpen(false)
      toast.success('Facture mise à jour avec succès')
    } catch (error) {
      console.error('Erreur lors de la mise à jour de la facture:', error)
    }
  }
  
  return (
    <div className="w-full max-w-none">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
        <div>
          <h1 className="text-2xl font-bold">Gestion des Factures</h1>
          <p className="text-muted-foreground">Consultez et gérez toutes les factures de vos clients</p>
        </div>
        <Button 
          variant="outline" 
          size="sm" 
          onClick={handleRefresh} 
          disabled={isLoading || isFetching}
          className="flex items-center gap-2"
        >
          <RefreshCw className={`h-4 w-4 ${isFetching ? 'animate-spin' : ''}`} />
          <span>Actualiser</span>
        </Button>
      </div>
      
      {/* Filtres et recherche */}
      <div className="flex flex-col md:flex-row justify-between gap-4 mb-6">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="w-full md:w-64">
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger>
                <SelectValue placeholder="Filtrer par statut" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous les statuts</SelectItem>
                <SelectItem value="0">En attente</SelectItem>
                <SelectItem value="1">Payée</SelectItem>
                <SelectItem value="2">Annulée</SelectItem>
                <SelectItem value="3">Remboursée</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="w-full md:w-80">
            <Input
              placeholder="Rechercher par n° de facture ou client"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </div>
      </div>
      
      {/* Liste des factures */}
      <Card className="w-full max-w-none">
        <CardHeader className="px-6">
          <div className="flex justify-between items-center">
            <div>
              <CardTitle>Factures</CardTitle>
              <CardDescription>
                Liste de toutes les factures générées
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="px-6 w-full max-w-none overflow-x-auto">
          {isLoading ? (
            <div className="flex justify-center items-center py-8">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
          ) : (
            <div className="w-full max-w-none rounded-md border overflow-x-auto" style={{ width: '100%' }}>
              <table className="w-full table-fixed" style={{ width: '100%', minWidth: '100%' }}>
                <thead>
                  <tr>
                    <th className="text-left p-4 font-medium" style={{ width: '15%' }}>N° de facture</th>
                    <th className="text-left p-4 font-medium" style={{ width: '20%' }}>Client</th>
                    <th className="text-left p-4 font-medium" style={{ width: '15%' }}>Date d'émission</th>
                    <th className="text-left p-4 font-medium" style={{ width: '10%' }}>Montant</th>
                    <th className="text-left p-4 font-medium" style={{ width: '10%' }}>Statut</th>
                    <th className="text-left p-4 font-medium" style={{ width: '20%' }}>Date de paiement</th>
                    <th className="text-left p-4 font-medium" style={{ width: '10%' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredInvoices.length > 0 ? (
                    filteredInvoices.map((invoice: Invoice) => (
                      <tr key={invoice.id} className="border-t">
                        <td className="p-4 align-middle" style={{ width: '15%' }}>{invoice.invoiceNumber}</td>
                        <td className="p-4 align-middle" style={{ width: '20%' }}>
                          {invoice.mobileUser ? (
                            <div>
                              <div>{invoice.mobileUser.firstName} {invoice.mobileUser.lastName}</div>
                              <div className="text-xs text-muted-foreground">{invoice.mobileUser.email}</div>
                            </div>
                          ) : 'N/A'}
                        </td>
                        <td className="p-4 align-middle" style={{ width: '15%' }}>{formatDate(invoice.createdAt)}</td>
                        <td className="p-4 align-middle" style={{ width: '10%' }}>{formatAmount(invoice.totalAmount)}</td>
                        <td className="p-4 align-middle" style={{ width: '10%' }}>
                          <Badge 
                            variant={getStatusBadgeVariant(invoice.status)} 
                            className="font-normal"
                          >
                            {getStatusLabel(invoice.status)}
                          </Badge>
                        </td>
                        <td className="p-4 align-middle" style={{ width: '20%' }}>{formatDate(invoice.paidAt)}</td>
                        <td className="p-4 align-middle" style={{ width: '10%' }}>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" className="h-8 w-8 p-0">
                                <span className="sr-only">Menu</span>
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onClick={() => handleViewInvoice(invoice)}>
                                <Eye className="mr-2 h-4 w-4" />
                                Voir les détails
                              </DropdownMenuItem>
                              <DropdownMenuItem onClick={() => handleEditInvoice(invoice)}>
                                <FileText className="mr-2 h-4 w-4" />
                                Modifier
                              </DropdownMenuItem>
                              {invoice.status === InvoiceStatus.Pending && (
                                <DropdownMenuItem onClick={() => handleOpenPayDialog(invoice)}>
                                  <CheckCircle className="mr-2 h-4 w-4" />
                                  Marquer comme payée
                                </DropdownMenuItem>
                              )}
                              {invoice.status === InvoiceStatus.Pending && (
                                <DropdownMenuItem onClick={() => handleCancelInvoice(invoice)}>
                                  <XCircle className="mr-2 h-4 w-4" />
                                  Annuler
                                </DropdownMenuItem>
                              )}
                              <DropdownMenuItem 
                                className="text-destructive focus:bg-destructive focus:text-destructive-foreground"
                                onClick={() => handleDeleteInvoice(invoice)}
                              >
                                Supprimer
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={7} className="p-4 text-center">
                        Aucune facture trouvée
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
      
      {/* Boîte de dialogue pour voir les détails */}
      <Dialog open={isViewInvoiceDialogOpen} onOpenChange={setIsViewInvoiceDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Détails de la facture</DialogTitle>
            <DialogDescription>
              Informations détaillées de la facture {selectedInvoice?.invoiceNumber}
            </DialogDescription>
          </DialogHeader>
          {invoiceDetails ? (
            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h3 className="text-lg font-semibold mb-2">Information de facture</h3>
                  <div className="space-y-1">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Numéro de facture:</span>
                      <span className="font-medium">{invoiceDetails.invoiceNumber}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Date d'émission:</span>
                      <span>{formatDate(invoiceDetails.createdAt)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Statut:</span>
                      <Badge variant={getStatusBadgeVariant(invoiceDetails.status)}>
                        {getStatusLabel(invoiceDetails.status)}
                      </Badge>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Montant total:</span>
                      <span className="font-bold">{formatAmount(invoiceDetails.totalAmount)}</span>
                    </div>
                  </div>
                </div>
                
                <div>
                  <h3 className="text-lg font-semibold mb-2">Informations client</h3>
                  <div className="space-y-1">
                    {invoiceDetails.mobileUser ? (
                      <>
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Nom:</span>
                          <span>{invoiceDetails.mobileUser.firstName} {invoiceDetails.mobileUser.lastName}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Email:</span>
                          <span>{invoiceDetails.mobileUser.email}</span>
                        </div>
                      </>
                    ) : (
                      <div>Informations client non disponibles</div>
                    )}
                  </div>
                </div>
              </div>
              
              <div className="border-t pt-4">
                <h3 className="text-lg font-semibold mb-2">Paiement</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Date de paiement:</span>
                      <span>{formatDate(invoiceDetails.paidAt)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Méthode de paiement:</span>
                      <span>{getPaymentMethodLabel(invoiceDetails.paymentMethod)}</span>
                    </div>
                  </div>
                  <div className="space-y-1">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Référence de paiement:</span>
                      <span>{invoiceDetails.paymentReference || 'N/A'}</span>
                    </div>
                  </div>
                </div>
              </div>
              
              {invoiceDetails.billingAddress && (
                <div className="border-t pt-4">
                  <h3 className="text-lg font-semibold mb-2">Adresse de facturation</h3>
                  <p className="whitespace-pre-line">{invoiceDetails.billingAddress}</p>
                </div>
              )}
              
              {invoiceDetails.notes && (
                <div className="border-t pt-4">
                  <h3 className="text-lg font-semibold mb-2">Notes</h3>
                  <p className="whitespace-pre-line">{invoiceDetails.notes}</p>
                </div>
              )}
            </div>
          ) : (
            <div className="flex justify-center items-center py-8">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
          )}
          <DialogFooter>
            <Button onClick={() => setIsViewInvoiceDialogOpen(false)}>
              Fermer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Boîte de dialogue pour éditer une facture */}
      <Dialog open={isEditInvoiceDialogOpen} onOpenChange={setIsEditInvoiceDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Modifier la facture</DialogTitle>
            <DialogDescription>
              Modifiez les informations de la facture {selectedInvoice?.invoiceNumber}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleEditSubmit}>
            <div className="grid gap-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="edit-status">Statut</Label>
                <Select 
                  value={editInvoice.status?.toString()} 
                  onValueChange={handleEditStatusChange}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Sélectionner un statut" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="0">En attente</SelectItem>
                    <SelectItem value="1">Payée</SelectItem>
                    <SelectItem value="2">Annulée</SelectItem>
                    <SelectItem value="3">Remboursée</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-billingAddress">Adresse de facturation</Label>
                <Textarea
                  id="edit-billingAddress"
                  value={editInvoice.billingAddress || ''}
                  onChange={(e) => setEditInvoice({ ...editInvoice, billingAddress: e.target.value })}
                  rows={3}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-notes">Notes</Label>
                <Textarea
                  id="edit-notes"
                  value={editInvoice.notes || ''}
                  onChange={(e) => setEditInvoice({ ...editInvoice, notes: e.target.value })}
                  rows={3}
                />
              </div>
            </div>
            <DialogFooter>
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => setIsEditInvoiceDialogOpen(false)}
              >
                Annuler
              </Button>
              <Button 
                type="submit" 
                disabled={updateInvoiceMutation.isPending}
              >
                {updateInvoiceMutation.isPending ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Mise à jour...
                  </>
                ) : (
                  'Mettre à jour'
                )}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Boîte de dialogue pour marquer comme payée */}
      <Dialog open={isPayInvoiceDialogOpen} onOpenChange={setIsPayInvoiceDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Marquer comme payée</DialogTitle>
            <DialogDescription>
              Enregistrer le paiement pour la facture {selectedInvoice?.invoiceNumber}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleMarkAsPaid}>
            <div className="grid gap-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="paymentMethod">Méthode de paiement</Label>
                <Select 
                  value={paymentInfo.paymentMethod.toString()} 
                  onValueChange={(value) => setPaymentInfo({ ...paymentInfo, paymentMethod: parseInt(value) as PaymentMethod })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Sélectionner une méthode" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="0">Carte de crédit</SelectItem>
                    <SelectItem value="1">Virement bancaire</SelectItem>
                    <SelectItem value="2">Espèces</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="paymentReference">Référence de paiement</Label>
                <Input
                  id="paymentReference"
                  value={paymentInfo.paymentReference}
                  onChange={(e) => setPaymentInfo({ ...paymentInfo, paymentReference: e.target.value })}
                  placeholder="N° de transaction, chèque, etc."
                />
              </div>
            </div>
            <DialogFooter>
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => setIsPayInvoiceDialogOpen(false)}
              >
                Annuler
              </Button>
              <Button 
                type="submit" 
                disabled={markAsPaidMutation.isPending}
              >
                {markAsPaidMutation.isPending ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Enregistrement...
                  </>
                ) : (
                  'Enregistrer le paiement'
                )}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Boîte de dialogue pour supprimer une facture */}
      <Dialog open={isDeleteInvoiceDialogOpen} onOpenChange={setIsDeleteInvoiceDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirmer la suppression</DialogTitle>
            <DialogDescription>
              Êtes-vous sûr de vouloir supprimer définitivement la facture {selectedInvoice?.invoiceNumber} ?
              Cette action est irréversible.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button 
              type="button" 
              variant="outline" 
              onClick={() => setIsDeleteInvoiceDialogOpen(false)}
            >
              Annuler
            </Button>
            <Button 
              type="button" 
              variant="destructive" 
              onClick={handleConfirmDelete}
              disabled={deleteInvoiceMutation.isPending}
            >
              {deleteInvoiceMutation.isPending ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Suppression...
                </>
              ) : (
                'Supprimer'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

export default Invoices 