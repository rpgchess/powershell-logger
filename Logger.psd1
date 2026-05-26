@{
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-1234-567890abcdef'
    Author = 'Claudio Almeida'
    CompanyName = 'Linx'
    Copyright = '(c) 2026 Linx. All rights reserved.'
    Description = 'Módulo Logger - Sistema completo de logging estruturado com múltiplos níveis, formatos (Simple/Detailed/Json), saída colorida e suporte a arquivo'
    PowerShellVersion = '5.1'
    
    RootModule = 'Logger.psm1'
    
    # Classes e enums carregados antes do módulo (essencial para 'using module')
    ScriptsToProcess = @(
        'Core\LoggerEnums.ps1',
        'Core\LoggerConfig.ps1',
        'Core\Logger.ps1'
    )
    
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('Logging', 'Log', 'Logger', 'Debug', 'Structured', 'Console', 'File', 'Json')
            ProjectUri = 'https://github.com/linx/powershell-logger'
            LicenseUri = 'https://github.com/linx/powershell-logger/blob/main/LICENSE'
            ReleaseNotes = @'
1.0.0 - 2026-05-25 (Initial Release)
FEATURES:
- ✨ Múltiplos níveis de log (DEBUG, INFO, WARN, ERROR, SUCCESS, FATAL)
- ✨ Múltiplos formatos (Simple, Detailed, Json)
- ✨ Saída colorida para console
- ✨ Saída para arquivo com buffer configurável
- ✨ Timestamp configurável (formato personalizado)
- ✨ Filtragem por nível mínimo
- ✨ Singleton pattern para uso global
- ✨ Exception logging detalhado (message, type, inner, stacktrace)
- ✨ Buffer flush automático e manual
- ✨ LoggerConfig para configuração flexível

CLASSES:
- Logger: Classe principal de logging
- LoggerConfig: Configuração do logger
- LogLevel enum: DEBUG, INFO, WARN, ERROR, SUCCESS, FATAL
- LogFormat enum: Simple, Detailed, Json

USAGE:
  # Logger básico
  $logger = [Logger]::new()
  $logger.Info('Mensagem')
  
  # Logger configurado
  $config = [LoggerConfig]::new([LogLevel]::DEBUG)
  $config.OutputFile = 'app.log'
  $logger = [Logger]::new($config)
  
  # Singleton
  [Logger]::Instance().Info('Global message')
'@
        }
    }
}
