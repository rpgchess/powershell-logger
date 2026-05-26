# Logger Module

> **Sistema completo de logging estruturado para PowerShell com múltiplos níveis, formatos e saída configurável**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Características](#-características)
- [Instalação](#-instalação)
- [Quick Start](#-quick-start)
- [Níveis de Log](#-níveis-de-log)
- [Formatos de Saída](#-formatos-de-saída)
- [Exemplos Práticos](#-exemplos-práticos)
- [Configuração](#-configuração)
- [Singleton Pattern](#-singleton-pattern)
- [Testes](#-testes)

---

## 🎯 Visão Geral

**Logger** é um módulo PowerShell que fornece sistema completo de logging estruturado com:

- ✅ **6 níveis de log** (DEBUG, INFO, WARN, ERROR, SUCCESS, FATAL)
- ✅ **3 formatos** (Simple, Detailed, Json)
- ✅ **Saída colorida** para console
- ✅ **Saída para arquivo** com buffer configurável
- ✅ **Exception logging** detalhado (message, type, inner exception, stacktrace)
- ✅ **Filtragem por nível** mínimo
- ✅ **Singleton pattern** para uso global
- ✅ **Timestamp configurável** (formato personalizado)
- ✅ **Buffer flush** automático e manual

---

## ✨ Características

### Níveis de Log

| Nível | Valor | Cor | Uso |
|-------|-------|-----|-----|
| DEBUG | 0 | Gray | Informações detalhadas para debug |
| INFO | 1 | Cyan | Informações gerais |
| WARN | 2 | Yellow | Avisos |
| ERROR | 3 | Red | Erros |
| SUCCESS | 4 | Green | Operações bem-sucedidas |
| FATAL | 5 | DarkRed | Erros fatais (flush imediato) |

### Formatos de Saída

- **Simple**: `[LEVEL] Message`
- **Detailed**: `[YYYY-MM-DD HH:MM:SS] [LEVEL] Message`
- **Json**: `{"timestamp":"...","level":"...","message":"..."}`

---

## 📦 Instalação

```powershell
# Clonar repositório
git clone https://github.com/linx/powershell-logger.git
cd powershell-logger

# Importar módulo
Import-Module .\Logger.psd1
```

---

## 🚀 Quick Start

### Logger Básico

```powershell
using module '.\Logger.psd1'

# Criar logger
$logger = [Logger]::new()

# Usar níveis diferentes
$logger.Debug('Debug detalhado')
$logger.Info('Aplicação iniciada')
$logger.Warn('Recurso limitado')
$logger.Error('Falha na operação')
$logger.Success('Processamento concluído')
$logger.Fatal('Erro crítico')
```

### Logger com Exception

```powershell
try {
    # Código que pode falhar
    Get-Item 'C:\arquivo-inexistente.txt'
} catch {
    $logger.Error('Arquivo não encontrado', $_.Exception)
}
```

### Logger com Arquivo

```powershell
$config = [LoggerConfig]::new()
$config.OutputFile = 'app.log'
$config.MinLevel = [LogLevel]::DEBUG

$logger = [Logger]::new($config)
$logger.Info('Log para arquivo e console')
$logger.Flush()  # Forçar escrita
```

---

## 📊 Níveis de Log

### DEBUG

Informações detalhadas para desenvolvimento e troubleshooting.

```powershell
$logger.Debug("Variável X = $X, Y = $Y")
$logger.Debug("Query executada: $sqlQuery")
```

### INFO

Informações gerais sobre execução.

```powershell
$logger.Info('Aplicação iniciada')
$logger.Info('Conectado ao banco de dados')
$logger.Info("Processados $count registros")
```

### WARN

Avisos que não impedem execução mas requerem atenção.

```powershell
$logger.Warn('API rate limit próximo do limite')
$logger.Warn('Cache não disponível, usando dados diretos')
```

### ERROR

Erros que afetam operação mas não são fatais.

```powershell
$logger.Error('Falha ao processar registro #123')
$logger.Error('Timeout na requisição HTTP', $exception)
```

### SUCCESS

Operações concluídas com sucesso (feedback positivo).

```powershell
$logger.Success('Backup concluído com sucesso')
$logger.Success("$totalFiles arquivos processados")
```

### FATAL

Erros críticos que impedem continuidade da aplicação.

```powershell
$logger.Fatal('Banco de dados inacessível')
$logger.Fatal('Configuração obrigatória ausente', $exception)
# FATAL sempre faz flush imediato
```

---

## 🎨 Formatos de Saída

### Simple

Formato minimalista sem timestamp.

```powershell
$config = [LoggerConfig]::new()
$config.Format = [LogFormat]::Simple
$config.IncludeTimestamp = $false

$logger = [Logger]::new($config)
$logger.Info('Mensagem simples')
# Saída: [INFO] Mensagem simples
```

### Detailed (Padrão)

Formato completo com timestamp.

```powershell
$config = [LoggerConfig]::new()
$config.Format = [LogFormat]::Detailed
$config.TimestampFormat = 'yyyy-MM-dd HH:mm:ss'

$logger = [Logger]::new($config)
$logger.Info('Mensagem detalhada')
# Saída: [2026-05-25 23:30:45] [INFO] Mensagem detalhada
```

### Json

Formato estruturado para parsing/análise.

```powershell
$config = [LoggerConfig]::new()
$config.Format = [LogFormat]::Json

$logger = [Logger]::new($config)
$logger.Info('Mensagem JSON')
# Saída: {"timestamp":"2026-05-25T23:30:45.123Z","level":"INFO","message":"Mensagem JSON"}
```

---

## 💡 Exemplos Práticos

### Script de Backup

```powershell
using module '.\Logger.psd1'

$config = [LoggerConfig]::new([LogLevel]::INFO)
$config.OutputFile = "backup-$(Get-Date -Format 'yyyyMMdd').log"

$logger = [Logger]::new($config)

$logger.Info('Backup iniciado')

try {
    $files = Get-ChildItem 'C:\Data' -Recurse
    $logger.Info("Encontrados $($files.Count) arquivos")
    
    foreach ($file in $files) {
        Copy-Item $file.FullName -Destination 'D:\Backup'
        $logger.Debug("Copiado: $($file.Name)")
    }
    
    $logger.Success('Backup concluído com sucesso')
} catch {
    $logger.Fatal('Backup falhou', $_.Exception)
    throw
} finally {
    $logger.Flush()
}
```

### API Integration

```powershell
using module '.\Logger.psd1'

$logger = [Logger]::new()

$logger.Info('Iniciando requisição API')

try {
    $response = Invoke-RestMethod -Uri 'https://api.example.com/data'
    $logger.Success("Recebidos $($response.Count) registros")
    
    if ($response.Count -eq 0) {
        $logger.Warn('API retornou lista vazia')
    }
} catch [System.Net.WebException] {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    switch ($statusCode) {
        429 { $logger.Warn('Rate limit excedido, aguardando...') }
        500 { $logger.Error('Erro no servidor API', $_.Exception) }
        default { $logger.Error("Erro HTTP $statusCode", $_.Exception) }
    }
} catch {
    $logger.Fatal('Erro inesperado na integração', $_.Exception)
}
```

---

## ⚙️ Configuração

### LoggerConfig

```powershell
$config = [LoggerConfig]::new()

# Nível mínimo (filtra logs abaixo)
$config.MinLevel = [LogLevel]::DEBUG

# Formato de saída
$config.Format = [LogFormat]::Detailed

# Timestamp
$config.IncludeTimestamp = $true
$config.TimestampFormat = 'yyyy-MM-dd HH:mm:ss.fff'

# Arquivo de saída
$config.OutputFile = 'app.log'
$config.AppendToFile = $true

# Buffer (número de logs antes de flush)
$config.BufferSize = 10

# Validar configuração
if ($config.IsValid()) {
    $logger = [Logger]::new($config)
}
```

### Métodos de Configuração

```powershell
$logger = [Logger]::new()

# Alterar nível mínimo em runtime
$logger.SetMinLevel([LogLevel]::WARN)

# Alterar arquivo de saída
$logger.SetOutputFile('new-log.log')

# Forçar flush do buffer
$logger.Flush()
```

---

## 🔄 Singleton Pattern

Use o padrão Singleton para logging global em toda a aplicação.

```powershell
using module '.\Logger.psd1'

# Obter instância global
$global:logger = [Logger]::Instance()

# Configurar uma vez
$global:logger.SetMinLevel([LogLevel]::DEBUG)
$global:logger.SetOutputFile('global.log')

# Usar em qualquer lugar da aplicação
function MyFunction {
    [Logger]::Instance().Info('Função executada')
}

# Em outro script
[Logger]::Instance().Warn('Aviso global')
```

---

## 🧪 Testes

### Teste Standalone

```powershell
# Teste básico
.\Test-Logger.ps1

# Teste com arquivo
.\Test-Logger.ps1 -OutputFile 'test.log'

# Teste com JSON
.\Test-Logger.ps1 -ShowJson
```

### Pester Tests

```powershell
# Instalar Pester 5.x
Install-Module Pester -MinimumVersion 5.0 -Force

# Executar testes
Invoke-Pester .\Tests\Logger.Tests.ps1
```

---

## 🔧 Comparação com Outras Soluções

| Feature | Logger Module | Log4Net | NLog | Write-Verbose |
|---------|---------------|---------|------|---------------|
| **Setup** | Zero config | Config XML | Config file | Built-in |
| **Níveis** | 6 níveis | 5 níveis | 6 níveis | 1 nível |
| **Formatos** | 3 formatos | Customizável | Customizável | Text only |
| **Cores** | ✅ Auto | ❌ | ❌ | ✅ |
| **Arquivo** | ✅ Com buffer | ✅ | ✅ | ❌ |
| **Json** | ✅ Nativo | ⚠️ Plugin | ⚠️ Plugin | ❌ |
| **Singleton** | ✅ | ⚠️ Manual | ⚠️ Manual | N/A |
| **PowerShell Native** | ✅ Classes | ❌ .NET | ❌ .NET | ✅ |

---

## 📝 Changelog

Ver [CHANGELOG.md](CHANGELOG.md) para histórico completo.

---

## 📄 Licença

MIT License - Ver [LICENSE](LICENSE) para detalhes.

---

## 👤 Autor

**Claudio Almeida**  
GitHub: [@claudioalmeida](https://github.com/claudioalmeida)  
Empresa: Linx SA

---

**Última atualização**: 2026-05-25  
**Versão**: 1.0.0
