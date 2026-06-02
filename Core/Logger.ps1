<#
.SYNOPSIS
    Classe principal Logger para logging estruturado.

.DESCRIPTION
    Fornece sistema completo de logging com suporte a:
    - Múltiplos níveis (DEBUG, INFO, WARN, ERROR, SUCCESS, FATAL)
    - Múltiplos formatos (Simple, Detailed, Json)
    - Saída colorida para console
    - Saída para arquivo com buffer
    - Timestamp configurável
    - Filtragem por nível mínimo

.EXAMPLE
    # Logger básico
    $logger = [Logger]::new()
    $logger.Info('Aplicação iniciada')
    $logger.Warn('Recurso limitado')
    $logger.Error('Falha na operação', $exception)

.EXAMPLE
    # Logger com configuração customizada
    $config = [LoggerConfig]::new()
    $config.MinLevel = [LogLevel]::DEBUG
    $config.Format = [LogFormat]::Json
    $config.OutputFile = 'app.log'
    
    $logger = [Logger]::new($config)
    $logger.Debug('Debug info')
    $logger.Flush()  # Forçar escrita no arquivo

.EXAMPLE
    # Logger estático (singleton)
    [Logger]::Instance().Info('Mensagem global')
    [Logger]::Instance().SetMinLevel([LogLevel]::WARN)

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 1.0.0
#>

class Logger {
    [LoggerConfig] $Config
    [string] $Name = ''
    hidden [System.Collections.Generic.List[string]] $Buffer
    hidden [object] $_lockObject
    hidden static [Logger] $_instance = $null
    
    # Construtor padrão
    Logger() {
        $this.Config = [LoggerConfig]::new()
        $this.Buffer = [System.Collections.Generic.List[string]]::new()
        $this._lockObject = [object]::new()
    }
    
    # Construtor com nome e configuração
    Logger([string] $Name, [LoggerConfig] $Config) {
        if (-not $Config.IsValid()) {
            throw "Configuração inválida: $($Config.ToString())"
        }
        
        $this.Name = $Name
        $this.Config = $Config
        $this.Buffer = [System.Collections.Generic.List[string]]::new()
        $this._lockObject = [object]::new()
    }
    
    # Construtor com configuração
    Logger([LoggerConfig] $Config) {
        if (-not $Config.IsValid()) {
            throw "Configuração inválida: $($Config.ToString())"
        }
        
        $this.Config = $Config
        $this.Buffer = [System.Collections.Generic.List[string]]::new()
        $this._lockObject = [object]::new()
    }
    
    # Singleton pattern
    static [Logger] Instance() {
        if ($null -eq [Logger]::_instance) {
            [Logger]::_instance = [Logger]::new()
        }
        return [Logger]::_instance
    }
    
    # Configurar nível mínimo
    [void] SetMinLevel([LogLevel] $Level) {
        $this.Config.MinLevel = $Level
    }
    
    # Configurar arquivo de saída
    [void] SetOutputFile([string] $FilePath) {
        $this.Config.OutputFile = $FilePath
        $this.Flush()  # Flush buffer existente
    }
    
    # Log genérico (com exception e dados estruturados)
    [void] Log([LogLevel] $Level, [string] $Message, [Exception] $Exception, [hashtable] $ExtraData) {
        # Filtrar por nível mínimo
        if ($Level -lt $this.Config.MinLevel) {
            return
        }
        
        $locked = $false
        try {
            [System.Threading.Monitor]::Enter($this._lockObject, [ref] $locked)
            
            # Formatar mensagem
            $formattedMessage = $this.FormatMessage($Level, $Message, $Exception, $ExtraData)
            
            # Saída para console
            $this.WriteToConsole($Level, $formattedMessage)
            
            # Saída para arquivo (se configurado)
            if (-not [string]::IsNullOrWhiteSpace($this.Config.OutputFile)) {
                $this.WriteToFile($formattedMessage)
            }
        } finally {
            if ($locked) { [System.Threading.Monitor]::Exit($this._lockObject) }
        }
    }
    
    # Log genérico (com exception)
    [void] Log([LogLevel] $Level, [string] $Message, [Exception] $Exception) {
        $this.Log($Level, $Message, $Exception, $null)
    }
    
    # Log genérico (sem exception)
    [void] Log([LogLevel] $Level, [string] $Message) {
        $this.Log($Level, $Message, $null, $null)
    }
    
    # Formatar mensagem baseado no formato configurado
    hidden [string] FormatMessage([LogLevel] $Level, [string] $Message, [Exception] $Exception, [hashtable] $ExtraData) {
        $output = ''
        $namePrefix = if ($this.Name) { "[$($this.Name)] " } else { '' }
        
        switch ($this.Config.Format) {
            ([LogFormat]::Simple) {
                $output = "${namePrefix}[$($Level.ToString().ToUpper())] $Message"
                if ($ExtraData -and $ExtraData.Count -gt 0) {
                    foreach ($key in $ExtraData.Keys) { $output += "`n  $key = $($ExtraData[$key])" }
                }
            }
            ([LogFormat]::Detailed) {
                $timestamp = ''
                if ($this.Config.IncludeTimestamp) {
                    $timestamp = "[$([DateTime]::Now.ToString($this.Config.TimestampFormat))] "
                }
                $output = "$timestamp${namePrefix}[$($Level.ToString().ToUpper())] $Message"
                if ($ExtraData -and $ExtraData.Count -gt 0) {
                    foreach ($key in $ExtraData.Keys) { $output += "`n  $key = $($ExtraData[$key])" }
                }
            }
            ([LogFormat]::Json) {
                $logEntry = @{
                    timestamp = [DateTime]::Now.ToString('o')
                    level = $Level.ToString().ToUpper()
                    message = $Message
                }
                
                if ($this.Name) { $logEntry.logger = $this.Name }
                
                if ($ExtraData -and $ExtraData.Count -gt 0) {
                    foreach ($key in $ExtraData.Keys) { $logEntry[$key] = $ExtraData[$key] }
                }
                
                if ($null -ne $Exception) {
                    $logEntry.exception = @{
                        message = $Exception.Message
                        type = $Exception.GetType().FullName
                    }
                    
                    if ($Exception.InnerException) {
                        $logEntry.exception.innerException = $Exception.InnerException.Message
                    }
                }
                
                $output = ($logEntry | ConvertTo-Json -Compress)
            }
            default {
                $output = "${namePrefix}[$($Level.ToString().ToUpper())] $Message"
            }
        }
        
        # Adicionar exception details (exceto para JSON que já incluiu)
        if ($null -ne $Exception -and $this.Config.Format -ne [LogFormat]::Json) {
            $output += "`n  Exception: $($Exception.Message)"
            $output += "`n  Type: $($Exception.GetType().FullName)"
            
            if ($Exception.InnerException) {
                $output += "`n  Inner: $($Exception.InnerException.Message)"
            }
            
            if ($Exception.StackTrace) {
                $output += "`n  StackTrace: $($Exception.StackTrace.Split("`n")[0])"
            }
        }
        
        return $output
    }
    
    # Escrever no console com cor apropriada
    hidden [void] WriteToConsole([LogLevel] $Level, [string] $Message) {
        $color = $this.GetLevelColor($Level)
        Write-Host $Message -ForegroundColor $color
    }
    
    # Escrever no arquivo (com buffer)
    hidden [void] WriteToFile([string] $Message) {
        $this.Buffer.Add($Message)
        
        # Flush se buffer cheio
        if ($this.Buffer.Count -ge $this.Config.BufferSize) {
            $this.Flush()
        }
    }
    
    # Forçar escrita do buffer no arquivo
    [void] Flush() {
        # Guard para Finalize() - $_lockObject pode ser null durante GC
        if ($null -eq $this._lockObject) {
            return
        }
        
        $locked = $false
        try {
            [System.Threading.Monitor]::Enter($this._lockObject, [ref] $locked)
            
            if ($this.Buffer.Count -eq 0) {
                return
            }
            
            if ([string]::IsNullOrWhiteSpace($this.Config.OutputFile)) {
                $this.Buffer.Clear()
                return
            }
            
            try {
                $content = $this.Buffer -join "`n"
                
                if ($this.Config.AppendToFile) {
                    Add-Content -Path $this.Config.OutputFile -Value $content -ErrorAction Stop
                } else {
                    Set-Content -Path $this.Config.OutputFile -Value $content -ErrorAction Stop
                    $this.Config.AppendToFile = $true
                }
                
                $this.Buffer.Clear()
            } catch {
                Write-Warning "Falha ao escrever no arquivo de log: $($_.Exception.Message)"
            }
        } finally {
            if ($locked) { [System.Threading.Monitor]::Exit($this._lockObject) }
        }
    }
    
    # Obter cor baseada no nível
    hidden [ConsoleColor] GetLevelColor([LogLevel] $Level) {
        switch ($Level) {
            ([LogLevel]::DEBUG)   { return [ConsoleColor]::Gray }
            ([LogLevel]::INFO)    { return [ConsoleColor]::Cyan }
            ([LogLevel]::WARN)    { return [ConsoleColor]::Yellow }
            ([LogLevel]::ERROR)   { return [ConsoleColor]::Red }
            ([LogLevel]::SUCCESS) { return [ConsoleColor]::Green }
            ([LogLevel]::FATAL)   { return [ConsoleColor]::DarkRed }
            default               { return [ConsoleColor]::White }
        }
        return [ConsoleColor]::White
    }
    
    # Atalhos por nível
    [void] Debug([string] $Message) {
        $this.Log([LogLevel]::DEBUG, $Message, $null, $null)
    }
    
    [void] Debug([string] $Message, [hashtable] $ExtraData) {
        $this.Log([LogLevel]::DEBUG, $Message, $null, $ExtraData)
    }
    
    [void] Info([string] $Message) {
        $this.Log([LogLevel]::INFO, $Message, $null, $null)
    }
    
    [void] Info([string] $Message, [hashtable] $ExtraData) {
        $this.Log([LogLevel]::INFO, $Message, $null, $ExtraData)
    }
    
    [void] Warn([string] $Message) {
        $this.Log([LogLevel]::WARN, $Message, $null, $null)
    }
    
    [void] Warn([string] $Message, [hashtable] $ExtraData) {
        $this.Log([LogLevel]::WARN, $Message, $null, $ExtraData)
    }
    
    [void] Error([string] $Message) {
        $this.Log([LogLevel]::ERROR, $Message, $null, $null)
    }
    
    [void] Error([string] $Message, [Exception] $Exception) {
        $this.Log([LogLevel]::ERROR, $Message, $Exception, $null)
    }
    
    [void] Error([string] $Message, [hashtable] $ExtraData) {
        $this.Log([LogLevel]::ERROR, $Message, $null, $ExtraData)
    }
    
    [void] Error([string] $Message, [Exception] $Exception, [hashtable] $ExtraData) {
        $this.Log([LogLevel]::ERROR, $Message, $Exception, $ExtraData)
    }
    
    [void] Success([string] $Message) {
        $this.Log([LogLevel]::SUCCESS, $Message, $null, $null)
    }
    
    [void] Success([string] $Message, [hashtable] $ExtraData) {
        $this.Log([LogLevel]::SUCCESS, $Message, $null, $ExtraData)
    }
    
    [void] Fatal([string] $Message) {
        $this.Log([LogLevel]::FATAL, $Message, $null, $null)
        $this.Flush()
    }
    
    [void] Fatal([string] $Message, [Exception] $Exception) {
        $this.Log([LogLevel]::FATAL, $Message, $Exception, $null)
        $this.Flush()
    }
    
    [void] Fatal([string] $Message, [hashtable] $ExtraData) {
        $this.Log([LogLevel]::FATAL, $Message, $null, $ExtraData)
        $this.Flush()
    }
    
    [void] Fatal([string] $Message, [Exception] $Exception, [hashtable] $ExtraData) {
        $this.Log([LogLevel]::FATAL, $Message, $Exception, $ExtraData)
        $this.Flush()
    }
    
    # Destrutor - garantir flush ao destruir objeto
    hidden [void] Finalize() {
        $this.Flush()
    }
}
