<#
.SYNOPSIS
    Enumeradores para o módulo Logger.

.DESCRIPTION
    Define os níveis de log utilizados no módulo Logger.
    
    Níveis disponíveis (em ordem crescente de severidade):
    - DEBUG (0): Informações detalhadas para debug
    - INFO (1): Informações gerais
    - WARN (2): Avisos
    - ERROR (3): Erros
    - SUCCESS (4): Operações bem-sucedidas
    - FATAL (5): Erros fatais que interrompem execução

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 1.0.0
#>

enum LogLevel {
    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    SUCCESS = 4
    FATAL   = 5
}

enum LogFormat {
    Simple      # [LEVEL] Message
    Detailed    # [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
    Json        # {"timestamp":"...", "level":"...", "message":"..."}
}
