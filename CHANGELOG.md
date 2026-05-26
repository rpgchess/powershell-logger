# Changelog

Todas as mudanças notáveis do projeto Logger Module serão documentadas aqui.

---

## [1.0.0] - 2026-05-25 (Initial Release)

### ✨ FEATURES

**Níveis de Log**:
- DEBUG (0): Informações detalhadas para debug
- INFO (1): Informações gerais
- WARN (2): Avisos
- ERROR (3): Erros
- SUCCESS (4): Operações bem-sucedidas
- FATAL (5): Erros fatais (flush imediato)

**Formatos de Saída**:
- Simple: `[LEVEL] Message`
- Detailed: `[YYYY-MM-DD HH:MM:SS] [LEVEL] Message`
- Json: Formato estruturado para parsing

**Saída**:
- Console colorizado por nível
- Arquivo com buffer configurável
- Flush automático (por tamanho) e manual
- Append ou sobrescrever arquivo

**Configuração**:
- LoggerConfig class com validação
- Timestamp configurável (formato custom)
- Filtragem por nível mínimo
- Buffer size configurável

**Funcionalidades Avançadas**:
- Exception logging detalhado (message, type, inner, stacktrace)
- Singleton pattern para uso global
- Runtime configuration (SetMinLevel, SetOutputFile)
- ToString() para debug de configuração

### 📦 CLASSES

- **Logger**: Classe principal de logging
  - Métodos: Debug, Info, Warn, Error, Success, Fatal, Log, Flush
  - Static: Instance() (singleton)
  - Configuration: SetMinLevel, SetOutputFile
  
- **LoggerConfig**: Configuração do logger
  - Properties: MinLevel, Format, IncludeTimestamp, OutputFile, BufferSize, etc
  - Methods: IsValid(), ToString()
  
- **LogLevel enum**: DEBUG, INFO, WARN, ERROR, SUCCESS, FATAL
- **LogFormat enum**: Simple, Detailed, Json

### 📖 DOCUMENTATION

- README.md: Guia completo com exemplos
- Test-Logger.ps1: Script de teste standalone
- Tests/Logger.Tests.ps1: Pester 5.x tests (35+ testes)

### 🏗️ STRUCTURE

```
logger/
├── Logger.psd1              # Module manifest
├── Logger.psm1              # Module loader
├── Core/
│   ├── LoggerEnums.ps1      # Enums (LogLevel, LogFormat)
│   ├── LoggerConfig.ps1     # Configuration class
│   └── Logger.ps1           # Main Logger class
├── Tests/
│   └── Logger.Tests.ps1     # Pester tests
├── Test-Logger.ps1          # Standalone test script
├── README.md                # Documentation
├── CHANGELOG.md             # (este arquivo)
├── LICENSE                  # MIT License
└── .gitignore               # Git ignore rules
```

### 🎯 USAGE EXAMPLES

**Basic**:
```powershell
using module '.\Logger.psd1'

$logger = [Logger]::new()
$logger.Info('Application started')
$logger.Success('Operation completed')
```

**Configured**:
```powershell
$config = [LoggerConfig]::new([LogLevel]::DEBUG)
$config.OutputFile = 'app.log'
$config.Format = [LogFormat]::Json

$logger = [Logger]::new($config)
$logger.Debug('Debug info')
$logger.Flush()
```

**Singleton**:
```powershell
[Logger]::Instance().Info('Global message')
[Logger]::Instance().SetMinLevel([LogLevel]::WARN)
```

### 🔒 KNOWN LIMITATIONS

- Não suporta múltiplos arquivos de saída simultâneos
- Não suporta log rotation automático (arquivo único)
- Não suporta async logging (síncrono apenas)

### 🚀 FUTURE ENHANCEMENTS (v1.1.0+)

- Log rotation (por tamanho ou data)
- Múltiplos outputs simultâneos
- Async logging para performance
- Custom formatters
- Network logging (syslog, graylog)

---

**Autor**: Claudio Almeida  
**Projeto**: https://github.com/rpgchess/powershell-logger.git
