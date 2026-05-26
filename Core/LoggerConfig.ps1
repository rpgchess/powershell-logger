<#
.SYNOPSIS
    Classe de configuração para Logger.

.DESCRIPTION
    Encapsula configurações do Logger: nível mínimo, formato, timestamp, saída para arquivo.

.EXAMPLE
    $config = [LoggerConfig]::new()
    $config.MinLevel = [LogLevel]::DEBUG
    $config.Format = [LogFormat]::Detailed
    $config.OutputFile = 'app.log'

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 1.0.0
#>

class LoggerConfig {
    # Nível mínimo de log
    [LogLevel] $MinLevel = [LogLevel]::INFO
    
    # Formato de saída
    [LogFormat] $Format = [LogFormat]::Detailed
    
    # Incluir timestamp
    [bool] $IncludeTimestamp = $true
    
    # Arquivo de saída (opcional)
    [string] $OutputFile = ''
    
    # Append ou sobrescrever arquivo
    [bool] $AppendToFile = $true
    
    # Buffer de logs antes de escrever no arquivo
    [int] $BufferSize = 10
    
    # Formato de timestamp
    [string] $TimestampFormat = 'yyyy-MM-dd HH:mm:ss'
    
    # Construtor padrão
    LoggerConfig() {
        # Default configuration
    }
    
    # Construtor com nível mínimo
    LoggerConfig([LogLevel] $MinLevel) {
        $this.MinLevel = $MinLevel
    }
    
    # Construtor completo
    LoggerConfig([LogLevel] $MinLevel, [LogFormat] $Format, [string] $OutputFile) {
        $this.MinLevel = $MinLevel
        $this.Format = $Format
        $this.OutputFile = $OutputFile
    }
    
    # Validar configuração
    [bool] IsValid() {
        # Se OutputFile especificado, verificar se diretório existe
        if (-not [string]::IsNullOrWhiteSpace($this.OutputFile)) {
            $dir = Split-Path $this.OutputFile -Parent
            if ($dir -and -not (Test-Path $dir)) {
                return $false
            }
        }
        
        return $true
    }
    
    # ToString para debug
    [string] ToString() {
        $output = "LoggerConfig { "
        $output += "MinLevel: $($this.MinLevel), "
        $output += "Format: $($this.Format), "
        $output += "IncludeTimestamp: $($this.IncludeTimestamp)"
        
        if (-not [string]::IsNullOrWhiteSpace($this.OutputFile)) {
            $output += ", OutputFile: $($this.OutputFile)"
        }
        
        $output += " }"
        return $output
    }
}
