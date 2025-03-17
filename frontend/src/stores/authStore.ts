import { create } from 'zustand'
import axios from 'axios'

interface AuthState {
  token: string | null
  isAuthenticated: boolean
  login: (username: string, password: string) => Promise<void>
  logout: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  token: localStorage.getItem('token'),
  isAuthenticated: !!localStorage.getItem('token'),
  
  login: async (username: string, password: string) => {
    try {
      console.log('Login attempt with:', { username, password }) // Debug
      const response = await axios.post('http://localhost:5094/api/auth/login', {
        username,
        password,
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      })
      console.log('Login response:', response.data) // Debug
      const token = response.data.token
      localStorage.setItem('token', token)
      set({ token, isAuthenticated: true })
    } catch (error) {
      console.error('Login error:', error) // Debug
      throw error
    }
  },

  logout: () => {
    localStorage.removeItem('token')
    set({ token: null, isAuthenticated: false })
  },
})) 