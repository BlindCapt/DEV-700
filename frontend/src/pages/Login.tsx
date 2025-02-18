import React from 'react';

export const Login = () => {
  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="w-full max-w-md p-8 space-y-4 bg-white rounded-lg shadow">
        <h1 className="text-2xl font-bold text-center">Connexion</h1>
        <form className="space-y-4">
          <div>
            <label className="block text-sm font-medium">Email</label>
            <input type="email" className="w-full p-2 border rounded" />
          </div>
          <div>
            <label className="block text-sm font-medium">Mot de passe</label>
            <input type="password" className="w-full p-2 border rounded" />
          </div>
          <button className="w-full p-2 bg-blue-600 text-white rounded">
            Se connecter
          </button>
        </form>
      </div>
    </div>
  );
}; 