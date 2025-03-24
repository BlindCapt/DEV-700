import { useState } from 'react'
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../components/ui/tabs"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "../components/ui/card"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../components/ui/table"
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
import { Button } from "../components/ui/button"
import { Input } from "../components/ui/input"
import { Label } from "../components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../components/ui/select"
import { toast } from "sonner"
import { MoreHorizontal, UserPlus, Loader2 } from "lucide-react"
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'
import { 
  useWebUsers, 
  useMobileUsers, 
  useCreateWebUser, 
  useUpdateWebUser, 
  useDeleteWebUser,
  useCreateMobileUser,
  useUpdateMobileUser,
  useDeleteMobileUser,
  WebUser,
  MobileUser,
  CreateWebUserDto,
  CreateMobileUserDto,
  UpdateWebUserDto,
  UpdateMobileUserDto
} from '../api/useUsers'

export const Users = () => {
  // État pour les formulaires et les dialogs
  const [isCreateWebUserDialogOpen, setIsCreateWebUserDialogOpen] = useState(false)
  const [isCreateMobileUserDialogOpen, setIsCreateMobileUserDialogOpen] = useState(false)
  const [isEditWebUserDialogOpen, setIsEditWebUserDialogOpen] = useState(false)
  const [isEditMobileUserDialogOpen, setIsEditMobileUserDialogOpen] = useState(false)
  const [isDeleteWebUserDialogOpen, setIsDeleteWebUserDialogOpen] = useState(false)
  const [isDeleteMobileUserDialogOpen, setIsDeleteMobileUserDialogOpen] = useState(false)
  const [selectedWebUser, setSelectedWebUser] = useState<WebUser | null>(null)
  const [selectedMobileUser, setSelectedMobileUser] = useState<MobileUser | null>(null)
  
  // Formulaire pour créer un utilisateur web
  const [newWebUser, setNewWebUser] = useState<CreateWebUserDto>({
    username: '',
    password: '',
    email: '',
    firstName: '',
    lastName: '',
    role: 'Employee'
  })
  
  // Formulaire pour créer un utilisateur mobile
  const [newMobileUser, setNewMobileUser] = useState<CreateMobileUserDto>({
    email: '',
    password: '',
    firstName: '',
    lastName: '',
    phoneNumber: ''
  })
  
  // Formulaire pour éditer un utilisateur web
  const [editWebUser, setEditWebUser] = useState<UpdateWebUserDto>({
    username: '',
    email: '',
    firstName: '',
    lastName: '',
    role: 'Employee',
    password: ''
  })
  
  // Formulaire pour éditer un utilisateur mobile
  const [editMobileUser, setEditMobileUser] = useState<UpdateMobileUserDto>({
    email: '',
    firstName: '',
    lastName: '',
    phoneNumber: '',
    isActive: true
  })
  
  // Récupération des données avec React Query
  const { data: webUsers, isLoading: isLoadingWebUsers } = useWebUsers()
  const { data: mobileUsers, isLoading: isLoadingMobileUsers } = useMobileUsers()
  
  // Mutations pour les opérations CRUD
  const createWebUserMutation = useCreateWebUser()
  const createMobileUserMutation = useCreateMobileUser()
  const updateWebUserMutation = useUpdateWebUser()
  const deleteWebUserMutation = useDeleteWebUser()
  const updateMobileUserMutation = useUpdateMobileUser()
  const deleteMobileUserMutation = useDeleteMobileUser()
  
  // Handlers pour la création d'un utilisateur web
  const handleCreateWebUserChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setNewWebUser({ ...newWebUser, [name]: value })
  }
  
  const handleCreateWebUserRoleChange = (value: 'Manager' | 'Employee') => {
    setNewWebUser({ ...newWebUser, role: value })
  }
  
  const handleCreateWebUserSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await createWebUserMutation.mutateAsync(newWebUser)
      setIsCreateWebUserDialogOpen(false)
      setNewWebUser({
        username: '',
        password: '',
        email: '',
        firstName: '',
        lastName: '',
        role: 'Employee'
      })
      toast.success('Utilisateur web créé avec succès')
    } catch (error) {
      if (error instanceof Error) {
        toast.error(`Erreur: ${error.message}`)
      } else {
        toast.error('Une erreur est survenue')
      }
    }
  }
  
  // Handlers pour la création d'un utilisateur mobile
  const handleCreateMobileUserChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setNewMobileUser({ ...newMobileUser, [name]: value })
  }
  
  const handleCreateMobileUserSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await createMobileUserMutation.mutateAsync(newMobileUser)
      setIsCreateMobileUserDialogOpen(false)
      setNewMobileUser({
        email: '',
        password: '',
        firstName: '',
        lastName: '',
        phoneNumber: ''
      })
      toast.success('Utilisateur mobile créé avec succès')
    } catch (error) {
      if (error instanceof Error) {
        toast.error(`Erreur: ${error.message}`)
      } else {
        toast.error('Une erreur est survenue')
      }
    }
  }
  
  // Handlers pour l'édition d'un utilisateur web
  const handleEditWebUser = (user: WebUser) => {
    setSelectedWebUser(user)
    setEditWebUser({
      username: user.username,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role as 'Manager' | 'Employee',
      password: ''
    })
    setIsEditWebUserDialogOpen(true)
  }
  
  const handleEditWebUserChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setEditWebUser({ ...editWebUser, [name]: value })
  }
  
  const handleEditWebUserRoleChange = (value: 'Manager' | 'Employee') => {
    setEditWebUser({ ...editWebUser, role: value })
  }
  
  const handleEditWebUserSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedWebUser) return
    
    try {
      await updateWebUserMutation.mutateAsync({
        id: selectedWebUser.id,
        user: editWebUser
      })
      setIsEditWebUserDialogOpen(false)
      toast.success('Utilisateur web mis à jour avec succès')
    } catch (error) {
      if (error instanceof Error) {
        toast.error(`Erreur: ${error.message}`)
      } else {
        toast.error('Une erreur est survenue')
      }
    }
  }
  
  // Handlers pour la suppression d'un utilisateur web
  const handleDeleteWebUser = (user: WebUser) => {
    setSelectedWebUser(user)
    setIsDeleteWebUserDialogOpen(true)
  }
  
  const handleConfirmDeleteWebUser = async () => {
    if (!selectedWebUser) return
    
    try {
      await deleteWebUserMutation.mutateAsync(selectedWebUser.id)
      setIsDeleteWebUserDialogOpen(false)
      toast.success('Utilisateur web supprimé avec succès')
    } catch (error) {
      if (error instanceof Error) {
        toast.error(`Erreur: ${error.message}`)
      } else {
        toast.error('Une erreur est survenue')
      }
    }
  }
  
  // Handlers pour l'édition d'un utilisateur mobile
  const handleEditMobileUser = (user: MobileUser) => {
    setSelectedMobileUser(user)
    setEditMobileUser({
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      phoneNumber: user.phoneNumber,
      isActive: user.isActive
    })
    setIsEditMobileUserDialogOpen(true)
  }
  
  const handleEditMobileUserChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setEditMobileUser({ ...editMobileUser, [name]: value })
  }
  
  const handleToggleMobileUserActiveStatus = () => {
    setEditMobileUser({ ...editMobileUser, isActive: !editMobileUser.isActive })
  }
  
  const handleEditMobileUserSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedMobileUser) return
    
    try {
      await updateMobileUserMutation.mutateAsync({
        id: selectedMobileUser.id,
        user: editMobileUser
      })
      setIsEditMobileUserDialogOpen(false)
      toast.success('Utilisateur mobile mis à jour avec succès')
    } catch (error) {
      if (error instanceof Error) {
        toast.error(`Erreur: ${error.message}`)
      } else {
        toast.error('Une erreur est survenue')
      }
    }
  }
  
  // Handlers pour la suppression d'un utilisateur mobile
  const handleDeleteMobileUser = (user: MobileUser) => {
    setSelectedMobileUser(user)
    setIsDeleteMobileUserDialogOpen(true)
  }
  
  const handleConfirmDeleteMobileUser = async () => {
    if (!selectedMobileUser) return
    
    try {
      await deleteMobileUserMutation.mutateAsync(selectedMobileUser.id)
      setIsDeleteMobileUserDialogOpen(false)
      toast.success('Utilisateur mobile supprimé avec succès')
    } catch (error) {
      if (error instanceof Error) {
        toast.error(`Erreur: ${error.message}`)
      } else {
        toast.error('Une erreur est survenue')
      }
    }
  }
  
  // Formatter les dates
  const formatDate = (dateString?: string) => {
    if (!dateString) return 'Jamais'
    return format(new Date(dateString), 'dd MMM yyyy, HH:mm', { locale: fr })
  }
  
  return (
    <div className="w-full max-w-none">
      <div className="flex justify-between items-center mb-4 w-full">
        <h1 className="text-2xl font-bold">Gestion des Utilisateurs</h1>
      </div>

      <div className="w-full max-w-none">
        <Tabs defaultValue="web" className="w-full max-w-none">
          <TabsList className="mb-4">
            <TabsTrigger value="web">Utilisateurs Web</TabsTrigger>
            <TabsTrigger value="mobile">Utilisateurs Mobile</TabsTrigger>
          </TabsList>
          
          <div className="w-full max-w-none">
            {/* Tab content for Web Users */}
            <TabsContent value="web" className="w-full max-w-none">
              <Card className="w-full max-w-none border-0 shadow-none">
                <CardHeader className="px-0 flex flex-row items-center justify-between">
                  <div>
                    <CardTitle>Utilisateurs Web</CardTitle>
                    <CardDescription>
                      Gérez les comptes utilisateurs ayant accès à l'interface d'administration.
                    </CardDescription>
                  </div>
                  <Dialog open={isCreateWebUserDialogOpen} onOpenChange={setIsCreateWebUserDialogOpen}>
                    <DialogTrigger asChild>
                      <Button size="sm">
                        <UserPlus className="mr-2 h-4 w-4" />
                        Ajouter un utilisateur
                      </Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Ajouter un utilisateur Web</DialogTitle>
                        <DialogDescription>
                          Créez un nouvel utilisateur pour accéder à l'interface d'administration.
                        </DialogDescription>
                      </DialogHeader>
                      <form onSubmit={handleCreateWebUserSubmit}>
                        <div className="grid gap-4 py-4">
                          <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                              <Label htmlFor="firstName">Prénom</Label>
                              <Input
                                id="firstName"
                                name="firstName"
                                value={newWebUser.firstName}
                                onChange={handleCreateWebUserChange}
                                required
                              />
                            </div>
                            <div className="space-y-2">
                              <Label htmlFor="lastName">Nom</Label>
                              <Input
                                id="lastName"
                                name="lastName"
                                value={newWebUser.lastName}
                                onChange={handleCreateWebUserChange}
                                required
                              />
                            </div>
                          </div>
                          <div className="space-y-2">
                            <Label htmlFor="username">Nom d'utilisateur</Label>
                            <Input
                              id="username"
                              name="username"
                              value={newWebUser.username}
                              onChange={handleCreateWebUserChange}
                              required
                            />
                          </div>
                          <div className="space-y-2">
                            <Label htmlFor="email">Email</Label>
                            <Input
                              id="email"
                              name="email"
                              type="email"
                              value={newWebUser.email}
                              onChange={handleCreateWebUserChange}
                              required
                            />
                          </div>
                          <div className="space-y-2">
                            <Label htmlFor="password">Mot de passe</Label>
                            <Input
                              id="password"
                              name="password"
                              type="password"
                              value={newWebUser.password}
                              onChange={handleCreateWebUserChange}
                              required
                            />
                          </div>
                          <div className="space-y-2">
                            <Label htmlFor="role">Rôle</Label>
                            <Select
                              value={newWebUser.role}
                              onValueChange={(value: 'Manager' | 'Employee') => handleCreateWebUserRoleChange(value)}
                            >
                              <SelectTrigger>
                                <SelectValue placeholder="Sélectionner un rôle" />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="Manager">Manager</SelectItem>
                                <SelectItem value="Employee">Employé</SelectItem>
                              </SelectContent>
                            </Select>
                          </div>
                        </div>
                        <DialogFooter>
                          <Button 
                            type="button" 
                            variant="outline" 
                            onClick={() => setIsCreateWebUserDialogOpen(false)}
                          >
                            Annuler
                          </Button>
                          <Button 
                            type="submit" 
                            disabled={createWebUserMutation.isPending}
                          >
                            {createWebUserMutation.isPending ? (
                              <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Création...
                              </>
                            ) : (
                              'Créer'
                            )}
                          </Button>
                        </DialogFooter>
                      </form>
                    </DialogContent>
                  </Dialog>
                </CardHeader>
                <CardContent className="p-0 w-full max-w-none overflow-x-auto">
                  {isLoadingWebUsers ? (
                    <div className="flex justify-center items-center py-8">
                      <Loader2 className="h-8 w-8 animate-spin text-primary" />
                    </div>
                  ) : (
                    <div className="w-full max-w-none rounded-md border overflow-x-auto" style={{ width: '100%' }}>
                      <table className="w-full table-fixed" style={{ width: '100%', minWidth: '100%' }}>
                        <thead>
                          <tr>
                            <th className="text-left p-4 font-medium" style={{ width: '15%' }}>Nom</th>
                            <th className="text-left p-4 font-medium" style={{ width: '15%' }}>Nom d'utilisateur</th>
                            <th className="text-left p-4 font-medium" style={{ width: '25%' }}>Email</th>
                            <th className="text-left p-4 font-medium" style={{ width: '15%' }}>Rôle</th>
                            <th className="text-left p-4 font-medium" style={{ width: '20%' }}>Dernière connexion</th>
                            <th className="text-left p-4 font-medium" style={{ width: '10%' }}>Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {webUsers && webUsers.length > 0 ? (
                            webUsers.map((user) => (
                              <tr key={user.id} className="border-t">
                                <td className="p-4 align-middle" style={{ width: '15%' }}>
                                  {user.firstName} {user.lastName}
                                </td>
                                <td className="p-4 align-middle" style={{ width: '15%' }}>{user.username}</td>
                                <td className="p-4 align-middle" style={{ width: '25%' }}>{user.email}</td>
                                <td className="p-4 align-middle" style={{ width: '15%' }}>
                                  <span className={`px-2 py-1 rounded-full text-xs ${
                                    user.role === 'Manager' 
                                      ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300' 
                                      : 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
                                  }`}>
                                    {user.role === 'Manager' ? 'Manager' : 'Employé'}
                                  </span>
                                </td>
                                <td className="p-4 align-middle" style={{ width: '20%' }}>{formatDate(user.lastLogin)}</td>
                                <td className="p-4 align-middle" style={{ width: '10%' }}>
                                  <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                      <Button variant="ghost" className="h-8 w-8 p-0">
                                        <span className="sr-only">Menu</span>
                                        <MoreHorizontal className="h-4 w-4" />
                                      </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end">
                                      <DropdownMenuItem onClick={() => handleEditWebUser(user)}>
                                        Modifier
                                      </DropdownMenuItem>
                                      <DropdownMenuItem 
                                        disabled={user.id === 1} 
                                        onClick={() => handleDeleteWebUser(user)}
                                        className="text-destructive focus:bg-destructive focus:text-destructive-foreground"
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
                              <td colSpan={6} className="text-center py-6">
                                Aucun utilisateur web trouvé
                              </td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
            
            {/* Tab content for Mobile Users */}
            <TabsContent value="mobile" className="w-full max-w-none">
              <Card className="w-full max-w-none border-0 shadow-none">
                <CardHeader className="px-0 flex flex-row items-center justify-between">
                  <div>
                    <CardTitle>Utilisateurs Mobile</CardTitle>
                    <CardDescription>
                      Gérez les comptes des utilisateurs de l'application mobile.
                    </CardDescription>
                  </div>
                  <Dialog open={isCreateMobileUserDialogOpen} onOpenChange={setIsCreateMobileUserDialogOpen}>
                    <DialogTrigger asChild>
                      <Button size="sm">
                        <UserPlus className="mr-2 h-4 w-4" />
                        Ajouter un utilisateur
                      </Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Ajouter un utilisateur Mobile</DialogTitle>
                        <DialogDescription>
                          Créez un nouvel utilisateur pour l'application mobile.
                        </DialogDescription>
                      </DialogHeader>
                      <form onSubmit={handleCreateMobileUserSubmit}>
                        <div className="grid gap-4 py-4">
                          <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                              <Label htmlFor="mobile-firstName">Prénom</Label>
                              <Input
                                id="mobile-firstName"
                                name="firstName"
                                value={newMobileUser.firstName}
                                onChange={handleCreateMobileUserChange}
                                required
                              />
                            </div>
                            <div className="space-y-2">
                              <Label htmlFor="mobile-lastName">Nom</Label>
                              <Input
                                id="mobile-lastName"
                                name="lastName"
                                value={newMobileUser.lastName}
                                onChange={handleCreateMobileUserChange}
                                required
                              />
                            </div>
                          </div>
                          <div className="space-y-2">
                            <Label htmlFor="mobile-email">Email</Label>
                            <Input
                              id="mobile-email"
                              name="email"
                              type="email"
                              value={newMobileUser.email}
                              onChange={handleCreateMobileUserChange}
                              required
                            />
                          </div>
                          <div className="space-y-2">
                            <Label htmlFor="mobile-phoneNumber">Numéro de téléphone</Label>
                            <Input
                              id="mobile-phoneNumber"
                              name="phoneNumber"
                              value={newMobileUser.phoneNumber}
                              onChange={handleCreateMobileUserChange}
                              required
                            />
                          </div>
                          <div className="space-y-2">
                            <Label htmlFor="mobile-password">Mot de passe</Label>
                            <Input
                              id="mobile-password"
                              name="password"
                              type="password"
                              value={newMobileUser.password}
                              onChange={handleCreateMobileUserChange}
                              required
                            />
                          </div>
                        </div>
                        <DialogFooter>
                          <Button 
                            type="button" 
                            variant="outline" 
                            onClick={() => setIsCreateMobileUserDialogOpen(false)}
                          >
                            Annuler
                          </Button>
                          <Button 
                            type="submit" 
                            disabled={createMobileUserMutation.isPending}
                          >
                            {createMobileUserMutation.isPending ? (
                              <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Création...
                              </>
                            ) : (
                              'Créer'
                            )}
                          </Button>
                        </DialogFooter>
                      </form>
                    </DialogContent>
                  </Dialog>
                </CardHeader>
                <CardContent className="p-0 w-full max-w-none overflow-x-auto">
                  {isLoadingMobileUsers ? (
                    <div className="flex justify-center items-center py-8">
                      <Loader2 className="h-8 w-8 animate-spin text-primary" />
                    </div>
                  ) : (
                    <div className="w-full max-w-none rounded-md border overflow-x-auto" style={{ width: '100%' }}>
                      <table className="w-full table-fixed" style={{ width: '100%', minWidth: '100%' }}>
                        <thead>
                          <tr>
                            <th className="text-left p-4 font-medium" style={{ width: '20%' }}>Nom</th>
                            <th className="text-left p-4 font-medium" style={{ width: '25%' }}>Email</th>
                            <th className="text-left p-4 font-medium" style={{ width: '15%' }}>Téléphone</th>
                            <th className="text-left p-4 font-medium" style={{ width: '15%' }}>Statut</th>
                            <th className="text-left p-4 font-medium" style={{ width: '15%' }}>Dernière connexion</th>
                            <th className="text-left p-4 font-medium" style={{ width: '10%' }}>Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {mobileUsers && mobileUsers.length > 0 ? (
                            mobileUsers.map((user) => (
                              <tr key={user.id} className="border-t">
                                <td className="p-4 align-middle" style={{ width: '20%' }}>
                                  {user.firstName} {user.lastName}
                                </td>
                                <td className="p-4 align-middle" style={{ width: '25%' }}>{user.email}</td>
                                <td className="p-4 align-middle" style={{ width: '15%' }}>{user.phoneNumber}</td>
                                <td className="p-4 align-middle" style={{ width: '15%' }}>
                                  <span className={`px-2 py-1 rounded-full text-xs ${
                                    user.isActive 
                                      ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
                                      : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
                                  }`}>
                                    {user.isActive ? 'Actif' : 'Inactif'}
                                  </span>
                                </td>
                                <td className="p-4 align-middle" style={{ width: '15%' }}>{formatDate(user.lastLogin)}</td>
                                <td className="p-4 align-middle" style={{ width: '10%' }}>
                                  <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                      <Button variant="ghost" className="h-8 w-8 p-0">
                                        <span className="sr-only">Menu</span>
                                        <MoreHorizontal className="h-4 w-4" />
                                      </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end">
                                      <DropdownMenuItem onClick={() => handleEditMobileUser(user)}>
                                        Modifier
                                      </DropdownMenuItem>
                                      <DropdownMenuItem 
                                        onClick={() => handleDeleteMobileUser(user)}
                                        className="text-destructive focus:bg-destructive focus:text-destructive-foreground"
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
                              <td colSpan={6} className="text-center py-6">
                                Aucun utilisateur mobile trouvé
                              </td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </div>
        </Tabs>
      </div>
      
      {/* Dialog pour éditer un utilisateur web */}
      <Dialog open={isEditWebUserDialogOpen} onOpenChange={setIsEditWebUserDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Modifier l'utilisateur Web</DialogTitle>
            <DialogDescription>
              Modifiez les informations de l'utilisateur.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleEditWebUserSubmit}>
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="edit-firstName">Prénom</Label>
                  <Input
                    id="edit-firstName"
                    name="firstName"
                    value={editWebUser.firstName}
                    onChange={handleEditWebUserChange}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="edit-lastName">Nom</Label>
                  <Input
                    id="edit-lastName"
                    name="lastName"
                    value={editWebUser.lastName}
                    onChange={handleEditWebUserChange}
                    required
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-username">Nom d'utilisateur</Label>
                <Input
                  id="edit-username"
                  name="username"
                  value={editWebUser.username}
                  onChange={handleEditWebUserChange}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-email">Email</Label>
                <Input
                  id="edit-email"
                  name="email"
                  type="email"
                  value={editWebUser.email}
                  onChange={handleEditWebUserChange}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-password">
                  Nouveau mot de passe (laisser vide pour ne pas changer)
                </Label>
                <Input
                  id="edit-password"
                  name="password"
                  type="password"
                  value={editWebUser.password}
                  onChange={handleEditWebUserChange}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-role">Rôle</Label>
                <Select
                  value={editWebUser.role}
                  onValueChange={(value: 'Manager' | 'Employee') => handleEditWebUserRoleChange(value)}
                  disabled={selectedWebUser?.id === 1}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Sélectionner un rôle" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Manager">Manager</SelectItem>
                    <SelectItem value="Employee">Employé</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <DialogFooter>
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => setIsEditWebUserDialogOpen(false)}
              >
                Annuler
              </Button>
              <Button 
                type="submit" 
                disabled={updateWebUserMutation.isPending}
              >
                {updateWebUserMutation.isPending ? (
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
      
      {/* Dialog pour supprimer un utilisateur web */}
      <Dialog open={isDeleteWebUserDialogOpen} onOpenChange={setIsDeleteWebUserDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirmer la suppression</DialogTitle>
            <DialogDescription>
              Êtes-vous sûr de vouloir supprimer l'utilisateur web {selectedWebUser?.firstName} {selectedWebUser?.lastName} ({selectedWebUser?.username}) ?
              Cette action est irréversible.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button 
              type="button" 
              variant="outline" 
              onClick={() => setIsDeleteWebUserDialogOpen(false)}
            >
              Annuler
            </Button>
            <Button 
              type="button" 
              variant="destructive" 
              onClick={handleConfirmDeleteWebUser}
              disabled={deleteWebUserMutation.isPending}
            >
              {deleteWebUserMutation.isPending ? (
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
      
      {/* Dialog pour éditer un utilisateur mobile */}
      <Dialog open={isEditMobileUserDialogOpen} onOpenChange={setIsEditMobileUserDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Modifier l'utilisateur Mobile</DialogTitle>
            <DialogDescription>
              Modifiez les informations de l'utilisateur mobile.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleEditMobileUserSubmit}>
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="edit-mobile-firstName">Prénom</Label>
                  <Input
                    id="edit-mobile-firstName"
                    name="firstName"
                    value={editMobileUser.firstName}
                    onChange={handleEditMobileUserChange}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="edit-mobile-lastName">Nom</Label>
                  <Input
                    id="edit-mobile-lastName"
                    name="lastName"
                    value={editMobileUser.lastName}
                    onChange={handleEditMobileUserChange}
                    required
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-mobile-email">Email</Label>
                <Input
                  id="edit-mobile-email"
                  name="email"
                  type="email"
                  value={editMobileUser.email}
                  onChange={handleEditMobileUserChange}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-mobile-phoneNumber">Téléphone</Label>
                <Input
                  id="edit-mobile-phoneNumber"
                  name="phoneNumber"
                  value={editMobileUser.phoneNumber}
                  onChange={handleEditMobileUserChange}
                  required
                />
              </div>
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="edit-mobile-isActive"
                  checked={editMobileUser.isActive}
                  onChange={handleToggleMobileUserActiveStatus}
                  className="rounded border-gray-300 text-primary focus:ring-primary"
                />
                <Label htmlFor="edit-mobile-isActive">Compte actif</Label>
              </div>
            </div>
            <DialogFooter>
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => setIsEditMobileUserDialogOpen(false)}
              >
                Annuler
              </Button>
              <Button 
                type="submit" 
                disabled={updateMobileUserMutation.isPending}
              >
                {updateMobileUserMutation.isPending ? (
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
      
      {/* Dialog pour supprimer un utilisateur mobile */}
      <Dialog open={isDeleteMobileUserDialogOpen} onOpenChange={setIsDeleteMobileUserDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirmer la suppression</DialogTitle>
            <DialogDescription>
              Êtes-vous sûr de vouloir supprimer l'utilisateur mobile {selectedMobileUser?.firstName} {selectedMobileUser?.lastName} ({selectedMobileUser?.email}) ?
              Cette action est irréversible.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button 
              type="button" 
              variant="outline" 
              onClick={() => setIsDeleteMobileUserDialogOpen(false)}
            >
              Annuler
            </Button>
            <Button 
              type="button" 
              variant="destructive" 
              onClick={handleConfirmDeleteMobileUser}
              disabled={deleteMobileUserMutation.isPending}
            >
              {deleteMobileUserMutation.isPending ? (
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

export default Users 