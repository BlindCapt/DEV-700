# Créez un fichier start-dev.ps1 avec ce contenu :
$ngrokPath = "C:\Users\matth\ngrok"  # Ajustez selon votre emplacement

# Démarrer l'API dans une nouvelle fenêtre
Start-Process powershell -ArgumentList "-NoExit -Command cd 'C:\Users\matth\Cours\epitech\Projet\DEV-700\backend\src\API'; dotnet run"

# Démarrer ngrok
Set-Location $ngrokPath
Write-Host "Démarrage de ngrok pour exposer l'API sur le port 5094..."
Write-Host "Utilisez l'URL fournie par ngrok dans votre application mobile."
.\ngrok.exe http 5094