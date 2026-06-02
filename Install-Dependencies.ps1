#Requires -Version 5.1

<#
.SYNOPSIS
    Instala dependências do módulo Logger.

.DESCRIPTION
    Instala módulos necessários para desenvolvimento e teste:
    - Pester 5.x: Framework de testes
    - PSScriptAnalyzer: Análise estática de código

    Suporta PowerShell 5.1+ (PowerShellGet) e PowerShell 7+ (PSResourceGet).

.PARAMETER Scope
    Escopo de instalação: CurrentUser ou AllUsers. Padrão: CurrentUser.

.PARAMETER Force
    Força reinstalação mesmo se já instalado.

.EXAMPLE
    PS> .\Install-Dependencies.ps1
    Instala dependências para o usuário atual.

.EXAMPLE
    PS> .\Install-Dependencies.ps1 -Scope AllUsers -Force
    Reinstala dependências para todos os usuários.

.NOTES
    Author: Claudio Almeida
    Date: 2026-06-01
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string] $Scope = 'CurrentUser',

    [switch] $Force
)

$ErrorActionPreference = 'Stop'

Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
Write-Host "  Logger Module - Install Dependencies" -ForegroundColor Cyan
Write-Host "$('=' * 70)`n" -ForegroundColor Cyan

$dependencies = @(
    @{ Name = 'Pester'; MinVersion = '5.0.0' }
    @{ Name = 'PSScriptAnalyzer'; MinVersion = '1.21.0' }
)

$usePSResourceGet = $PSVersionTable.PSVersion.Major -ge 7
$installed = 0; $skipped = 0; $failed = 0

foreach ($dep in $dependencies) {
    Write-Host "`n[$($dep.Name)]" -ForegroundColor Cyan
    $module = Get-Module -ListAvailable -Name $dep.Name |
        Where-Object { $_.Version -ge [Version]$dep.MinVersion } |
        Select-Object -First 1

    if ($module -and -not $Force) {
        Write-Host "  ✓ v$($module.Version) já instalado" -ForegroundColor Green
        $skipped++; continue
    }

    try {
        $installParams = @{
            Name = $dep.Name
            MinimumVersion = $dep.MinVersion
            Scope = $Scope
            Force = $Force
            AllowClobber = $true
            SkipPublisherCheck = $true
        }

        if ($usePSResourceGet) {
            if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet)) {
                Install-Module -Name Microsoft.PowerShell.PSResourceGet -Force -Scope $Scope -AllowClobber
            }
            Install-PSResource @installParams -Repository PSGallery -TrustRepository
        } else {
            Install-Module @installParams -Repository PSGallery
        }

        Write-Host "  ✓ Instalado com sucesso" -ForegroundColor Green
        $installed++
    } catch {
        Write-Host "  ✗ Falha: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n$('=' * 70)" -ForegroundColor Green
Write-Host "  Resumo: $installed instalados, $skipped já existentes, $failed falhas" -ForegroundColor Cyan

if ($failed -gt 0) { exit 1 } else { exit 0 }
