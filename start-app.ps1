<#
    start-app.ps1 — Lance l'application Geoworld MODERNISEE en local.

    - Active le profil "local" (MySQL local : root, sans mot de passe, base geoworld)
    - Demarre le serveur MySQL d'EasyPHP s'il n'est pas deja lance
    - Lance le serveur PHP integre sur le port choisi, route sur index.php

    Utilisation :
        .\start-app.ps1
        .\start-app.ps1 -Port 9000 -Debug

    Si PowerShell refuse d'executer le script :
        Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#>

param(
    [int]    $Port = 8001,
    [switch] $Debug
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listenHost = "127.0.0.1"

# --- 1. S'assurer que MySQL ecoute sur le port 3306 ---
$mysqlUp = (Test-NetConnection -ComputerName $listenHost -Port 3306 -WarningAction SilentlyContinue).TcpTestSucceeded
if (-not $mysqlUp) {
    $dbServer = "C:\Program Files (x86)\EasyPHP-Devserver-17\eds-binaries\dbserver\mysql5717x86x210507080732\bin\eds-dbserver.exe"
    if (Test-Path $dbServer) {
        Write-Host "Demarrage du serveur MySQL d'EasyPHP..." -ForegroundColor Yellow
        Start-Process -FilePath $dbServer -WindowStyle Minimized
        for ($i = 0; $i -lt 15; $i++) {
            Start-Sleep -Seconds 1
            if ((Test-NetConnection -ComputerName $listenHost -Port 3306 -WarningAction SilentlyContinue).TcpTestSucceeded) {
                $mysqlUp = $true; break
            }
        }
    }
    if (-not $mysqlUp) {
        Write-Warning "MySQL ne repond pas sur ${listenHost}:3306. Demarrez-le via EasyPHP, puis relancez."
    }
} else {
    Write-Host "MySQL est deja en ecoute sur ${listenHost}:3306." -ForegroundColor Green
}

# --- 2. Profil local lu par config.php ---
$env:GEOWORLD_ENV   = "local"
$env:GEOWORLD_DEBUG = if ($Debug) { "1" } else { "0" }

# --- 3. Lancer le serveur PHP integre, racine = ce dossier ---
# index.php est le point d'entree unique : toute requete inconnue y est routee.
Write-Host ""
Write-Host "App modernisee : http://${listenHost}:${Port}/" -ForegroundColor Cyan
Write-Host "(Ctrl+C pour arreter)" -ForegroundColor DarkGray
Write-Host ""

php -S "${listenHost}:${Port}" -t $root
