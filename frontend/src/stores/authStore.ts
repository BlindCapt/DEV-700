import { create } from 'zustand'
import axios from 'axios'

interface AuthState {
  token: string | null
  isAuthenticated: boolean
  user: any | null
  login: (username: string, password: string) => Promise<void>
  logout: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  token: localStorage.getItem('token'),
  isAuthenticated: !!localStorage.getItem('token'),
  user: null,
  
  login: async (username: string, password: string) => {
    try {
      console.log('Login attempt with:', { username, password }) // Debug
      
      // Vérifier que l'URL est correcte
      const url = 'http://localhost:5094/api/web/auth/login'
      console.log('Calling API at:', url)
      
      const response = await axios.post(url, {
        username,
        password,
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      })
      
      console.log('Login response:', response.data) // Debug
      const { token, user } = response.data
      
      // Vérifier que le token est bien reçu
      if (!token) {
        console.error('Token not received in response')
        throw new Error('Token not received')
      }
      
      localStorage.setItem('token', token)
      set({ token, isAuthenticated: true, user })
    } catch (error: any) {
      console.error('Login error:', error) // Debug
      
      // Afficher plus de détails sur l'erreur
      if (error.response) {
        console.error('Error response:', {
          status: error.response.status,
          data: error.response.data,
          headers: error.response.headers
        })
      } else if (error.request) {
        console.error('Error request:', error.request)
      } else {
        console.error('Error message:', error.message)
      }
      
      throw error
    }
  },

  logout: () => {
    localStorage.removeItem('token')
    set({ token: null, isAuthenticated: false, user: null })
  },
})) 