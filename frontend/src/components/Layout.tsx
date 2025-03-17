import * as React from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Home, Package, LogOut } from 'lucide-react'
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuButton,
  SidebarProvider,
} from '@/components/ui/sidebar'
import { useAuthStore } from '../stores/authStore'
import { Button } from './ui/button'

export const Layout = ({ children }: { children: React.ReactNode }) => {
  const logout = useAuthStore((state) => state.logout)
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <SidebarProvider>
      <div className="flex h-screen bg-background">
        <Sidebar className="bg-card border-border">
          <SidebarHeader className="border-border">
            <h2 className="text-xl font-bold p-4 text-foreground">T-DEV-700</h2>
          </SidebarHeader>
          <SidebarContent className="flex flex-col h-[calc(100%-4rem)]">
            <SidebarGroup>
              <SidebarGroupContent>
                <SidebarMenu>
                  <SidebarMenuItem>
                    <SidebarMenuButton asChild>
                      <Link to="/" className="flex items-center text-foreground">
                        <Home className="mr-2 h-4 w-4" />
                        <span>Dashboard</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                  <SidebarMenuItem>
                    <SidebarMenuButton asChild>
                      <Link to="/products" className="flex items-center text-foreground">
                        <Package className="mr-2 h-4 w-4" />
                        <span>Produits</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>
            
            {/* Bouton de déconnexion en bas */}
            <div className="mt-auto p-4 border-t">
              <Button 
                variant="ghost" 
                className="w-full justify-start"
                onClick={handleLogout}
              >
                <LogOut className="mr-2 h-4 w-4" />
                Déconnexion
              </Button>
            </div>
          </SidebarContent>
        </Sidebar>
        <main className="flex-1 overflow-y-auto bg-background text-foreground p-8">
          {children}
        </main>
      </div>
    </SidebarProvider>
  )
}