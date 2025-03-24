import * as React from 'react'
import { useState } from 'react'
import axios from 'axios'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from '@/components/ui/dialog'
import { FileUp, AlertCircle } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Progress } from '@/components/ui/progress'

interface ProductImport {
  id: string; // code-barres
  prix: number;
  quantite: number;
}

export function BulkImportDialog() {
  const [open, setOpen] = useState(false)
  const [file, setFile] = useState<File | null>(null)
  const [importing, setImporting] = useState(false)
  const [progress, setProgress] = useState(0)
  const [results, setResults] = useState<{
    success: number;
    failed: number;
    errors: string[];
  }>({ success: 0, failed: 0, errors: [] })
  const queryClient = useQueryClient()

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setFile(e.target.files[0])
      // Réinitialiser les résultats lors de la sélection d'un nouveau fichier
      setResults({ success: 0, failed: 0, errors: [] })
    }
  }

  const importProducts = async () => {
    if (!file) return

    try {
      setImporting(true)
      setProgress(0)
      setResults({ success: 0, failed: 0, errors: [] })

      const reader = new FileReader()
      
      reader.onload = async (e) => {
        try {
          const jsonContent = JSON.parse(e.target?.result as string)
          const products = Array.isArray(jsonContent) ? jsonContent : [jsonContent]
          
          // Vérifier que le format est correct
          for (let i = 0; i < products.length; i++) {
            const product = products[i]
            if (!product.id || product.prix === undefined || product.quantite === undefined) {
              throw new Error(`Produit #${i + 1}: Format invalide, il manque des propriétés (id, prix, ou quantite)`)
            }
          }

          // Envoyer les données au backend en une seule requête
          const response = await axios.post('http://localhost:5094/api/products/bulk-import', products)

          if (response.status === 200) {
            const result = response.data
            setResults({
              success: result.successCount,
              failed: result.failedCount,
              errors: result.errors || []
            })
            
            // Recharger les produits
            queryClient.invalidateQueries({ queryKey: ['products'] })
          } else {
            throw new Error("Erreur lors de l'importation")
          }
        } catch (error: any) {
          if (error.response?.data?.errors) {
            setResults({
              success: 0,
              failed: 1,
              errors: error.response.data.errors
            })
          } else {
            setResults({
              success: 0,
              failed: 1,
              errors: [error.message || 'Format JSON invalide. Veuillez vérifier le contenu du fichier.']
            })
          }
        }
        
        setImporting(false)
      }
      
      reader.readAsText(file)
    } catch (error: any) {
      setResults({
        success: 0,
        failed: 1,
        errors: [error.message || 'Erreur lors de l\'importation']
      })
      setImporting(false)
    }
  }

  const resetForm = () => {
    setFile(null)
    setResults({ success: 0, failed: 0, errors: [] })
  }

  return (
    <Dialog open={open} onOpenChange={(newOpen) => {
      setOpen(newOpen)
      if (!newOpen) resetForm()
    }}>
      <DialogTrigger asChild>
        <Button variant="outline">
          <FileUp className="mr-2 h-4 w-4" /> Importer en masse
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <DialogTitle>Importer des produits en masse</DialogTitle>
        </DialogHeader>
        
        <div className="space-y-4 py-4">
          <p className="text-sm text-gray-600">
            Importez un fichier JSON contenant une liste de produits à mettre à jour. 
            Chaque produit doit avoir un identifiant (code-barres), un prix et une quantité.
          </p>
          
          <div className="format-example p-3 bg-gray-100 rounded text-xs">
            <p className="font-medium mb-1">Format attendu:</p>
            <pre>{`[
  {
    "id": "10101010", // Code-barres du produit
    "prix": 10,
    "quantite": 25
  },
  {
    "id": "12121212",
    "prix": 15,
    "quantite": 40
  }
]`}</pre>
          </div>

          {!importing && !results.success && !results.failed && (
            <div className="flex items-center justify-center border-2 border-dashed border-gray-300 rounded-md p-6">
              <label className="flex flex-col items-center cursor-pointer">
                <FileUp className="h-8 w-8 text-gray-400 mb-2" />
                <span className="text-sm font-medium mb-1">
                  {file ? file.name : "Sélectionner un fichier JSON"}
                </span>
                <span className="text-xs text-gray-500">
                  {file ? `${(file.size / 1024).toFixed(2)} Ko` : "Cliquez pour parcourir"}
                </span>
                <input
                  type="file"
                  accept=".json"
                  className="hidden"
                  onChange={handleFileChange}
                />
              </label>
            </div>
          )}

          {importing && (
            <div className="space-y-2">
              <p className="text-sm">Importation en cours...</p>
              <Progress value={progress} className="h-2" />
              <p className="text-xs text-gray-500 text-right">{progress}%</p>
            </div>
          )}

          {(results.success > 0 || results.failed > 0) && !importing && (
            <div className="space-y-3">
              <div className="flex justify-between text-sm">
                <span>Produits importés avec succès: {results.success}</span>
                <span>Échecs: {results.failed}</span>
              </div>
              
              {results.errors.length > 0 && (
                <Alert variant="destructive">
                  <AlertCircle className="h-4 w-4" />
                  <AlertTitle>Erreurs d'importation</AlertTitle>
                  <AlertDescription>
                    <div className="max-h-32 overflow-y-auto text-xs">
                      {results.errors.map((error, index) => (
                        <p key={index}>{error}</p>
                      ))}
                    </div>
                  </AlertDescription>
                </Alert>
              )}
            </div>
          )}
        </div>

        <DialogFooter>
          {!importing && !results.success && !results.failed && (
            <>
              <Button variant="ghost" onClick={() => setOpen(false)}>Annuler</Button>
              <Button onClick={importProducts} disabled={!file}>Importer</Button>
            </>
          )}
          
          {!importing && (results.success > 0 || results.failed > 0) && (
            <>
              <Button variant="ghost" onClick={resetForm}>Nouveau fichier</Button>
              <Button onClick={() => setOpen(false)}>Fermer</Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
} 