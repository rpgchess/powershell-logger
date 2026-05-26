<#
.SYNOPSIS
    Módulo Logger - Sistema de logging estruturado.

.DESCRIPTION
    Fornece classes Logger e LoggerConfig para logging completo com:
    - Múltiplos níveis (DEBUG, INFO, WARN, ERROR, SUCCESS, FATAL)
    - Múltiplos formatos (Simple, Detailed, Json)
    - Saída colorida para console
    - Saída para arquivo
    
    O módulo carrega classes via ScriptsToProcess no manifesto.

.EXAMPLE
    using module '.\Logger.psd1'
    
    $logger = [Logger]::new()
    $logger.Info('Aplicação iniciada')
    $logger.Warn('Recurso limitado')
    $logger.Error('Falha na operação')

.EXAMPLE
    using module '.\Logger.psd1'
    
    $config = [LoggerConfig]::new()
    $config.MinLevel = [LogLevel]::DEBUG
    $config.OutputFile = 'app.log'
    
    $logger = [Logger]::new($config)
    $logger.Debug('Debug detalhado')
    $logger.Flush()

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 1.0.0
#>

# Classes são carregadas via ScriptsToProcess no manifesto .psd1
# Exportar tudo (classes são acessíveis via 'using module')
Export-ModuleMember -Function * -Variable * -Alias * -Cmdlet *
