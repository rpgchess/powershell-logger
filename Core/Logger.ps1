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
    hidden [System.Collections.Generic.List[string]] $Buffer
    hidden static [Logger] $_instance = $null
    
    # Construtor padrão
    Logger() {
        $this.Config = [LoggerConfig]::new()
        $this.Buffer = [System.Collections.Generic.List[string]]::new()
    }
    
    # Construtor com configuração
    Logger([LoggerConfig] $Config) {
        if (-not $Config.IsValid()) {
            throw "Configuração inválida: $($Config.ToString())"
        }
        
        $this.Config = $Config
        $this.Buffer = [System.Collections.Generic.List[string]]::new()
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
    
    # Log genérico (com exception)
    [void] Log([LogLevel] $Level, [string] $Message, [Exception] $Exception) {
        # Filtrar por nível mínimo
        if ($Level -lt $this.Config.MinLevel) {
            return
        }
        
        # Formatar mensagem
        $formattedMessage = $this.FormatMessage($Level, $Message, $Exception)
        
        # Saída para console
        $this.WriteToConsole($Level, $formattedMessage)
        
        # Saída para arquivo (se configurado)
        if (-not [string]::IsNullOrWhiteSpace($this.Config.OutputFile)) {
            $this.WriteToFile($formattedMessage)
        }
    }
    
    # Log genérico (sem exception)
    [void] Log([LogLevel] $Level, [string] $Message) {
        $this.Log($Level, $Message, $null)
    }
    
    # Formatar mensagem baseado no formato configurado
    hidden [string] FormatMessage([LogLevel] $Level, [string] $Message, [Exception] $Exception) {
        $output = ''
        
        switch ($this.Config.Format) {
            ([LogFormat]::Simple) {
                $output = "[$($Level.ToString().ToUpper())] $Message"
            }
            ([LogFormat]::Detailed) {
                $timestamp = ''
                if ($this.Config.IncludeTimestamp) {
                    $timestamp = "[$([DateTime]::Now.ToString($this.Config.TimestampFormat))] "
                }
                $output = "$timestamp[$($Level.ToString().ToUpper())] $Message"
            }
            ([LogFormat]::Json) {
                $logEntry = @{
                    timestamp = [DateTime]::Now.ToString('o')
                    level = $Level.ToString().ToUpper()
                    message = $Message
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
                $output = "[$($Level.ToString().ToUpper())] $Message"
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
                $this.Config.AppendToFile = $true  # Após primeira escrita, sempre append
            }
            
            $this.Buffer.Clear()
        } catch {
            Write-Warning "Falha ao escrever no arquivo de log: $($_.Exception.Message)"
        }
    }
    
    # Obter cor baseada no nível
    hidden [string] GetLevelColor([LogLevel] $Level) {
        switch ($Level) {
            ([LogLevel]::DEBUG)   { return 'Gray' }
            ([LogLevel]::INFO)    { return 'Cyan' }
            ([LogLevel]::WARN)    { return 'Yellow' }
            ([LogLevel]::ERROR)   { return 'Red' }
            ([LogLevel]::SUCCESS) { return 'Green' }
            ([LogLevel]::FATAL)   { return 'DarkRed' }
            default               { return 'White' }
        }
        
        return 'White'  # Fallback (não deve ser atingido)
    }
    
    # Atalhos por nível
    [void] Debug([string] $Message) {
        $this.Log([LogLevel]::DEBUG, $Message)
    }
    
    [void] Info([string] $Message) {
        $this.Log([LogLevel]::INFO, $Message)
    }
    
    [void] Warn([string] $Message) {
        $this.Log([LogLevel]::WARN, $Message)
    }
    
    [void] Error([string] $Message) {
        $this.Log([LogLevel]::ERROR, $Message)
    }
    
    [void] Error([string] $Message, [Exception] $Exception) {
        $this.Log([LogLevel]::ERROR, $Message, $Exception)
    }
    
    [void] Success([string] $Message) {
        $this.Log([LogLevel]::SUCCESS, $Message)
    }
    
    [void] Fatal([string] $Message) {
        $this.Log([LogLevel]::FATAL, $Message)
        $this.Flush()  # Garantir que FATAL seja escrito imediatamente
    }
    
    [void] Fatal([string] $Message, [Exception] $Exception) {
        $this.Log([LogLevel]::FATAL, $Message, $Exception)
        $this.Flush()  # Garantir que FATAL seja escrito imediatamente
    }
    
    # Destrutor - garantir flush ao destruir objeto
    hidden [void] Finalize() {
        $this.Flush()
    }
}
