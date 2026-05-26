#Requires -Version 5.1

<#
.SYNOPSIS
    Script de build para o projeto Logger Module.

.DESCRIPTION
    Build automation com múltiplas tarefas: Clean, Analyze, Test, Build, Package, All.
    
    Tarefas disponíveis:
    - Clean: Limpa arquivos temporários e de build
    - Analyze: Executa análise estática com PSScriptAnalyzer
    - Test: Executa testes com Pester
    - Build: Valida manifest e estrutura do módulo
    - Package: Cria pacote ZIP para distribuição
    - All: Executa todas as tarefas em sequência

.PARAMETER Task
    Tarefa a ser executada. Padrão: All

.PARAMETER Configuration
    Configuração de build (Debug ou Release). Padrão: Debug

.PARAMETER SkipTests
    Pula execução de testes (útil para builds rápidos).

.EXAMPLE
    PS> .\Build.ps1
    Executa build completo (todas as tarefas).

.EXAMPLE
    PS> .\Build.ps1 -Task Test
    Executa apenas os testes.

.EXAMPLE
    PS> .\Build.ps1 -Task All -Configuration Release
    Build completo em modo Release.

.EXAMPLE
    PS> .\Build.ps1 -Task Build -SkipTests
    Build sem executar testes.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateSet('Clean', 'Analyze', 'Test', 'Build', 'Package', 'All')]
    [string] $Task = 'All',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Debug',
    
    [Parameter(Mandatory = $false)]
    [switch] $SkipTests
)

#region Variáveis
$script:ExitCode = 0
$script:StartTime = Get-Date

$script:Paths = @{
    Root = $PSScriptRoot
    Tests = Join-Path $PSScriptRoot 'Tests'
    TestResults = Join-Path $PSScriptRoot 'Tests' 'reports'
    Package = Join-Path $PSScriptRoot 'Package'
    Manifest = Join-Path $PSScriptRoot 'Logger.psd1'
}
#endregion

#region Funções Auxiliares
function Write-TaskHeader {
    [CmdletBinding()]
    param([string] $TaskName)
    
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  TASK: $TaskName" -ForegroundColor Cyan
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
}

function Write-TaskResult {
    [CmdletBinding()]
    param(
        [string] $TaskName,
        [bool] $Success,
        [int] $DurationMs
    )
    
    $status = if ($Success) { '✓ SUCESSO' } else { '✗ FALHA' }
    $color = if ($Success) { 'Green' } else { 'Red' }
    
    Write-Host "`n$status - $TaskName ($DurationMs ms)" -ForegroundColor $color
}

function Invoke-Task {
    [CmdletBinding()]
    param(
        [string] $Name,
        [scriptblock] $ScriptBlock
    )
    
    Write-TaskHeader -TaskName $Name
    
    $taskStart = Get-Date
    $success = $true
    
    try {
        & $ScriptBlock
    } catch {
        Write-Error "Erro na tarefa '$Name': $($_.Exception.Message)"
        $success = $false
        $script:ExitCode = 1
    }
    
    $duration = [int]((Get-Date) - $taskStart).TotalMilliseconds
    Write-TaskResult -TaskName $Name -Success $success -DurationMs $duration
    
    return $success
}
#endregion

#region Tasks
function Task-Clean {
    Write-Host "Limpando arquivos temporários..."
    
    # Test Reports
    if (Test-Path $script:Paths.TestResults) {
        Remove-Item $script:Paths.TestResults -Recurse -Force
        Write-Host "  Removido: Tests/reports/" -ForegroundColor Gray
    }
    
    # Package
    if (Test-Path $script:Paths.Package) {
        Remove-Item $script:Paths.Package -Recurse -Force
        Write-Host "  Removido: Package/" -ForegroundColor Gray
    }
    
    # Log files
    $logFiles = Get-ChildItem $script:Paths.Root -Filter '*.log' -File
    if ($logFiles) {
        $logFiles | Remove-Item -Force
        Write-Host "  Removido: $($logFiles.Count) arquivo(s) .log" -ForegroundColor Gray
    }
    
    Write-Host "Limpeza concluída." -ForegroundColor Green
}

function Task-Analyze {
    Write-Host "Executando análise estática com PSScriptAnalyzer..."
    
    # Verificar se PSScriptAnalyzer está instalado
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        throw "PSScriptAnalyzer não está instalado. Execute: Install-Module PSScriptAnalyzer"
    }
    
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    
    # Analisar arquivos PowerShell
    $filesToAnalyze = Get-ChildItem $script:Paths.Root -Include '*.ps1', '*.psm1' -Recurse |
        Where-Object { $_.FullName -notlike '*\TestResults\*' -and $_.FullName -notlike '*\Package\*' }
    
    Write-Host "Analisando $($filesToAnalyze.Count) arquivo(s)..."
    
    $results = $filesToAnalyze | Invoke-ScriptAnalyzer -Severity Warning, Error
    
    if ($results) {
        Write-Host "`nProblemas encontrados:" -ForegroundColor Yellow
        $results | Format-Table Severity, RuleName, ScriptName, Line, Message -AutoSize
        
        $errorCount = ($results | Where-Object Severity -eq 'Error').Count
        if ($errorCount -gt 0) {
            throw "PSScriptAnalyzer encontrou $errorCount erro(s) crítico(s)"
        }
    } else {
        Write-Host "Nenhum problema encontrado." -ForegroundColor Green
    }
}

function Task-Test {
    if ($SkipTests) {
        Write-Host "Testes pulados (SkipTests = $true)" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Executando testes com Pester..."
    
    # Verificar se Pester está instalado
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        throw "Pester não está instalado. Execute: Install-Module Pester -MinimumVersion 5.0"
    }
    
    Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
    
    # Criar diretório de resultados
    if (-not (Test-Path $script:Paths.TestResults)) {
        New-Item -ItemType Directory -Path $script:Paths.TestResults -Force | Out-Null
    }
    
    # Configurar Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = Join-Path $script:Paths.Tests 'Logger.Tests.ps1'
    $pesterConfig.Run.Exit = $false
    $pesterConfig.Output.Verbosity = 'Detailed'
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path $script:Paths.TestResults 'TestResults.xml'
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    $pesterConfig.CodeCoverage.Enabled = $false
    
    # Executar testes
    $result = Invoke-Pester -Configuration $pesterConfig
    
    # Exibir resultados
    Write-Host "`nResumo dos Testes:" -ForegroundColor Cyan
    Write-Host "  Passou: $($result.PassedCount)" -ForegroundColor Green
    Write-Host "  Falhou: $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { 'Green' } else { 'Red' })
    Write-Host "  Pulado: $($result.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Total:  $($result.TotalCount)" -ForegroundColor Cyan
    Write-Host "  Duração: $([int]$result.Duration.TotalMilliseconds) ms" -ForegroundColor Gray
    
    if ($result.FailedCount -gt 0) {
        throw "$($result.FailedCount) teste(s) falharam"
    }
}

function Task-Build {
    Write-Host "Validando manifest e estrutura do módulo..."
    
    # Validar manifest
    if (-not (Test-Path $script:Paths.Manifest)) {
        throw "Manifest não encontrado: $($script:Paths.Manifest)"
    }
    
    try {
        $manifest = Test-ModuleManifest -Path $script:Paths.Manifest -ErrorAction Stop
        Write-Host "  ✓ Manifest válido" -ForegroundColor Green
        Write-Host "    Nome: $($manifest.Name)" -ForegroundColor Gray
        Write-Host "    Versão: $($manifest.Version)" -ForegroundColor Gray
        Write-Host "    Autor: $($manifest.Author)" -ForegroundColor Gray
    } catch {
        throw "Manifest inválido: $($_.Exception.Message)"
    }
    
    # Validar estrutura
    $requiredFiles = @(
        'Logger.psd1',
        'Logger.psm1',
        'Core\LoggerEnums.ps1',
        'Core\LoggerConfig.ps1',
        'Core\Logger.ps1'
    )
    
    foreach ($file in $requiredFiles) {
        $path = Join-Path $script:Paths.Root $file
        if (-not (Test-Path $path)) {
            throw "Arquivo obrigatório não encontrado: $file"
        }
    }
    
    Write-Host "  ✓ Estrutura válida" -ForegroundColor Green
}

function Task-Package {
    Write-Host "Criando pacote ZIP para distribuição..."
    
    # Criar diretório de package
    if (-not (Test-Path $script:Paths.Package)) {
        New-Item -ItemType Directory -Path $script:Paths.Package -Force | Out-Null
    }
    
    # Obter versão do manifest
    $manifest = Test-ModuleManifest -Path $script:Paths.Manifest -ErrorAction Stop
    $version = $manifest.Version.ToString()
    
    # Nome do pacote
    $packageName = "Logger-v$version-$Configuration.zip"
    $packagePath = Join-Path $script:Paths.Package $packageName
    
    # Arquivos para incluir
    $filesToPackage = @(
        'Logger.psd1',
        'Logger.psm1',
        'Core\*',
        'README.md',
        'CHANGELOG.md',
        'LICENSE'
    )
    
    # Criar ZIP temporário
    $tempDir = Join-Path $env:TEMP "Logger-$version"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    foreach ($pattern in $filesToPackage) {
        $items = Get-ChildItem (Join-Path $script:Paths.Root $pattern) -ErrorAction SilentlyContinue
        
        foreach ($item in $items) {
            $relativePath = $item.FullName.Replace($script:Paths.Root, '').TrimStart('\')
            $destination = Join-Path $tempDir $relativePath
            
            $destDir = Split-Path $destination -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            
            Copy-Item $item.FullName -Destination $destination -Force
        }
    }
    
    # Criar ZIP
    if (Test-Path $packagePath) {
        Remove-Item $packagePath -Force
    }
    
    Compress-Archive -Path "$tempDir\*" -DestinationPath $packagePath -Force
    
    # Limpar temporário
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host "  ✓ Pacote criado: $packageName" -ForegroundColor Green
    Write-Host "    Path: $packagePath" -ForegroundColor Gray
    Write-Host "    Tamanho: $([math]::Round((Get-Item $packagePath).Length / 1KB, 2)) KB" -ForegroundColor Gray
}

function Task-All {
    $tasks = @('Clean', 'Analyze', 'Test', 'Build', 'Package')
    
    foreach ($taskName in $tasks) {
        if ($SkipTests -and $taskName -eq 'Test') {
            continue
        }
        
        $success = Invoke-Task -Name $taskName -ScriptBlock {
            & "Task-$taskName"
        }
        
        if (-not $success) {
            Write-Error "Build falhou na tarefa: $taskName"
            return
        }
    }
    
    Write-Host "`n$('=' * 70)" -ForegroundColor Green
    Write-Host "  BUILD COMPLETO COM SUCESSO!" -ForegroundColor Green
    Write-Host "$('=' * 70)" -ForegroundColor Green
}
#endregion

#region Main
Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
Write-Host "  Logger Module - Build Script" -ForegroundColor Cyan
Write-Host "$('=' * 70)" -ForegroundColor Cyan
Write-Host "  Tarefa: $Task" -ForegroundColor Gray
Write-Host "  Configuração: $Configuration" -ForegroundColor Gray
Write-Host "  Pular Testes: $SkipTests" -ForegroundColor Gray

try {
    if ($Task -eq 'All') {
        Task-All
    } else {
        Invoke-Task -Name $Task -ScriptBlock {
            & "Task-$Task"
        }
    }
} catch {
    Write-Error "Build falhou: $($_.Exception.Message)"
    $script:ExitCode = 1
} finally {
    $duration = [int]((Get-Date) - $script:StartTime).TotalSeconds
    
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  Build finalizado em $duration segundos" -ForegroundColor Cyan
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
}

exit $script:ExitCode
#endregion
