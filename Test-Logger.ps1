#Requires -Version 5.1

<#
.SYNOPSIS
    Testa funcionalidade básica do módulo Logger.

.DESCRIPTION
    Script de teste standalone para validar operações de logging.
    Testa todos os níveis, formatos e saída para arquivo.
    
    Pré-requisitos:
    - Módulo Logger disponível no diretório atual

.PARAMETER OutputFile
    Arquivo de log para testar saída em arquivo.

.PARAMETER ShowJson
    Exibe também exemplo de formato JSON.

.EXAMPLE
    PS> .\Test-Logger.ps1
    Executa testes básicos com saída em console.

.EXAMPLE
    PS> .\Test-Logger.ps1 -OutputFile 'test.log'
    Testa saída para arquivo.

.EXAMPLE
    PS> .\Test-Logger.ps1 -ShowJson
    Inclui exemplos de formato JSON.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [Alias('File', 'Log')]
    [string] $OutputFile = '',
    
    [Parameter(Mandatory = $false)]
    [Alias('Json')]
    [switch] $ShowJson
)

begin {
    # Importar módulo
    $modulePath = Join-Path $PSScriptRoot 'Logger.psd1'
    Import-Module $modulePath -Force
    
    $script:TestsPassed = 0
    $script:TestsFailed = 0
}

process {
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  Logger Module - Teste Funcional" -ForegroundColor Cyan
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
    
    # Teste 1: Logger básico
    Write-Host "`n1. Testando Logger básico..." -ForegroundColor Yellow
    
    try {
        $logger = [Logger]::new()
        Write-Host "   ✓ Logger instanciado" -ForegroundColor Green
        $script:TestsPassed++
    } catch {
        Write-Host "   ✗ Erro ao instanciar: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
        throw
    }
    
    # Teste 2: Todos os níveis
    Write-Host "`n2. Testando todos os níveis de log..." -ForegroundColor Yellow
    
    try {
        $logger.Debug('Mensagem de debug')
        $logger.Info('Mensagem informativa')
        $logger.Warn('Aviso importante')
        $logger.Error('Erro encontrado')
        $logger.Success('Operação bem-sucedida')
        
        Write-Host "   ✓ Todos os níveis funcionando" -ForegroundColor Green
        $script:TestsPassed++
    } catch {
        Write-Host "   ✗ Erro nos níveis: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
    }
    
    # Teste 3: Exception logging
    Write-Host "`n3. Testando logging de exceptions..." -ForegroundColor Yellow
    
    try {
        $exception = [System.IO.FileNotFoundException]::new('Arquivo não encontrado')
        $logger.Error('Erro ao processar arquivo', $exception)
        
        Write-Host "   ✓ Exception logging funcionando" -ForegroundColor Green
        $script:TestsPassed++
    } catch {
        Write-Host "   ✗ Erro no exception logging: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
    }
    
    # Teste 4: Singleton
    Write-Host "`n4. Testando pattern Singleton..." -ForegroundColor Yellow
    
    try {
        $instance1 = [Logger]::Instance()
        $instance2 = [Logger]::Instance()
        
        if ($instance1 -eq $instance2) {
            Write-Host "   ✓ Singleton funcionando (mesma instância)" -ForegroundColor Green
            $script:TestsPassed++
        } else {
            throw "Instâncias diferentes retornadas"
        }
        
        [Logger]::Instance().Info('Mensagem via singleton')
    } catch {
        Write-Host "   ✗ Erro no singleton: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
    }
    
    # Teste 5: Configuração customizada
    Write-Host "`n5. Testando configuração customizada..." -ForegroundColor Yellow
    
    try {
        $config = [LoggerConfig]::new()
        $config.MinLevel = [LogLevel]::WARN
        $config.Format = [LogFormat]::Simple
        $config.IncludeTimestamp = $false
        
        $customLogger = [Logger]::new($config)
        $customLogger.Debug('Debug não deve aparecer')
        $customLogger.Info('Info não deve aparecer')
        $customLogger.Warn('Warn deve aparecer')
        
        Write-Host "   ✓ Configuração customizada funcionando" -ForegroundColor Green
        $script:TestsPassed++
    } catch {
        Write-Host "   ✗ Erro na configuração: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
    }
    
    # Teste 6: Saída para arquivo (se especificado)
    if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
        Write-Host "`n6. Testando saída para arquivo..." -ForegroundColor Yellow
        
        try {
            # Remover arquivo se existir
            if (Test-Path $OutputFile) {
                Remove-Item $OutputFile -Force
            }
            
            $fileConfig = [LoggerConfig]::new()
            $fileConfig.OutputFile = $OutputFile
            $fileConfig.BufferSize = 3
            
            $fileLogger = [Logger]::new($fileConfig)
            $fileLogger.Info('Log 1')
            $fileLogger.Info('Log 2')
            $fileLogger.Info('Log 3')  # Deve triggar flush
            $fileLogger.Flush()  # Garantir que tudo foi escrito
            
            if (Test-Path $OutputFile) {
                $content = Get-Content $OutputFile
                Write-Host "   ✓ Arquivo criado com $($content.Count) linhas" -ForegroundColor Green
                Write-Host "   Conteúdo: $($OutputFile)" -ForegroundColor Gray
                $script:TestsPassed++
            } else {
                throw "Arquivo não foi criado"
            }
        } catch {
            Write-Host "   ✗ Erro na saída para arquivo: $($_.Exception.Message)" -ForegroundColor Red
            $script:TestsFailed++
        }
    }
    
    # Teste 7: Formato JSON (se solicitado)
    if ($ShowJson) {
        Write-Host "`n7. Testando formato JSON..." -ForegroundColor Yellow
        
        try {
            $jsonConfig = [LoggerConfig]::new()
            $jsonConfig.Format = [LogFormat]::Json
            
            $jsonLogger = [Logger]::new($jsonConfig)
            $jsonLogger.Info('Mensagem em JSON')
            
            $exception = [System.ArgumentException]::new('Argumento inválido')
            $jsonLogger.Error('Erro em JSON', $exception)
            
            Write-Host "   ✓ Formato JSON funcionando" -ForegroundColor Green
            $script:TestsPassed++
        } catch {
            Write-Host "   ✗ Erro no formato JSON: $($_.Exception.Message)" -ForegroundColor Red
            $script:TestsFailed++
        }
    }
}

end {
    # Resumo
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  Resumo dos Testes" -ForegroundColor Cyan
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
    
    Write-Host "`nEstatísticas:" -ForegroundColor Gray
    Write-Host "  Sucesso: $script:TestsPassed" -ForegroundColor Green
    Write-Host "  Falhas:  $script:TestsFailed" -ForegroundColor $(if ($script:TestsFailed -eq 0) { 'Green' } else { 'Red' })
    Write-Host "  Total:   $($script:TestsPassed + $script:TestsFailed)" -ForegroundColor Cyan
    
    if ($script:TestsFailed -eq 0) {
        Write-Host "`n✓ Módulo Logger funcionando corretamente!`n" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n✗ Alguns testes falharam. Verifique os erros acima.`n" -ForegroundColor Red
        exit 1
    }
}
