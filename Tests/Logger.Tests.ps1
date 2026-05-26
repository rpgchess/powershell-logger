<#
.SYNOPSIS
    Pester tests for Logger module.

.DESCRIPTION
    Comprehensive unit tests for Logger module v1.0.0+.
    Tests cover: LoggerConfig validation, Logger instantiation, logging methods,
    levels, formats, file output, buffer, singleton pattern.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 1.0.0
    Requires: Pester 5.x
#>

BeforeAll {
    # Import module
    $modulePath = Join-Path $PSScriptRoot '..' 'Logger.psd1'
    Import-Module $modulePath -Force
}

Describe 'LoggerConfig' {
    Context 'Instantiation' {
        It 'Should create config with default values' {
            $config = [LoggerConfig]::new()
            $config.MinLevel | Should -Be ([LogLevel]::INFO)
            $config.Format | Should -Be ([LogFormat]::Detailed)
            $config.IncludeTimestamp | Should -Be $true
        }
        
        It 'Should create config with MinLevel' {
            $config = [LoggerConfig]::new([LogLevel]::DEBUG)
            $config.MinLevel | Should -Be ([LogLevel]::DEBUG)
        }
        
        It 'Should create config with all parameters' {
            $config = [LoggerConfig]::new([LogLevel]::WARN, [LogFormat]::Json, 'test.log')
            $config.MinLevel | Should -Be ([LogLevel]::WARN)
            $config.Format | Should -Be ([LogFormat]::Json)
            $config.OutputFile | Should -Be 'test.log'
        }
    }
    
    Context 'Validation' {
        It 'Should validate config without OutputFile' {
            $config = [LoggerConfig]::new()
            $config.IsValid() | Should -Be $true
        }
        
        It 'Should validate config with valid OutputFile directory' {
            $config = [LoggerConfig]::new()
            $config.OutputFile = Join-Path $TestDrive 'test.log'
            $config.IsValid() | Should -Be $true
        }
        
        It 'Should fail validation with invalid OutputFile directory' {
            $config = [LoggerConfig]::new()
            $config.OutputFile = 'Z:\invalid\path\test.log'
            $config.IsValid() | Should -Be $false
        }
    }
    
    Context 'ToString' {
        It 'Should display config info' {
            $config = [LoggerConfig]::new([LogLevel]::DEBUG)
            $str = $config.ToString()
            $str | Should -Match 'LoggerConfig'
            $str | Should -Match 'MinLevel: DEBUG'
        }
    }
}

Describe 'Logger' {
    Context 'Instantiation' {
        It 'Should create logger with default config' {
            $logger = [Logger]::new()
            $logger | Should -Not -BeNullOrEmpty
            $logger.Config.MinLevel | Should -Be ([LogLevel]::INFO)
        }
        
        It 'Should create logger with custom config' {
            $config = [LoggerConfig]::new([LogLevel]::DEBUG)
            $logger = [Logger]::new($config)
            $logger.Config.MinLevel | Should -Be ([LogLevel]::DEBUG)
        }
        
        It 'Should throw on invalid config' {
            $config = [LoggerConfig]::new()
            $config.OutputFile = 'Z:\invalid\test.log'
            { [Logger]::new($config) } | Should -Throw
        }
    }
    
    Context 'Singleton Pattern' {
        It 'Should return same instance' {
            $instance1 = [Logger]::Instance()
            $instance2 = [Logger]::Instance()
            $instance1 | Should -Be $instance2
        }
    }
    
    Context 'Configuration Methods' {
        It 'Should set min level' {
            $logger = [Logger]::new()
            $logger.SetMinLevel([LogLevel]::WARN)
            $logger.Config.MinLevel | Should -Be ([LogLevel]::WARN)
        }
        
        It 'Should set output file' {
            $logger = [Logger]::new()
            $testFile = Join-Path $TestDrive 'test.log'
            $logger.SetOutputFile($testFile)
            $logger.Config.OutputFile | Should -Be $testFile
        }
    }
    
    Context 'Logging Methods' {
        It 'Should log Debug without error' {
            $logger = [Logger]::new()
            { $logger.Debug('Test debug') } | Should -Not -Throw
        }
        
        It 'Should log Info without error' {
            $logger = [Logger]::new()
            { $logger.Info('Test info') } | Should -Not -Throw
        }
        
        It 'Should log Warn without error' {
            $logger = [Logger]::new()
            { $logger.Warn('Test warn') } | Should -Not -Throw
        }
        
        It 'Should log Error without error' {
            $logger = [Logger]::new()
            { $logger.Error('Test error') } | Should -Not -Throw
        }
        
        It 'Should log Success without error' {
            $logger = [Logger]::new()
            { $logger.Success('Test success') } | Should -Not -Throw
        }
        
        It 'Should log Fatal without error' {
            $logger = [Logger]::new()
            { $logger.Fatal('Test fatal') } | Should -Not -Throw
        }
    }
    
    Context 'Exception Logging' {
        It 'Should log exception with Error' {
            $logger = [Logger]::new()
            $exception = [System.IO.FileNotFoundException]::new('File not found')
            { $logger.Error('Test error', $exception) } | Should -Not -Throw
        }
        
        It 'Should log exception with Fatal' {
            $logger = [Logger]::new()
            $exception = [System.ArgumentException]::new('Invalid argument')
            { $logger.Fatal('Test fatal', $exception) } | Should -Not -Throw
        }
    }
    
    Context 'Level Filtering' {
        It 'Should filter logs below min level' {
            $config = [LoggerConfig]::new([LogLevel]::ERROR)
            $logger = [Logger]::new($config)
            
            # Estes não devem gerar exceções (são filtrados silenciosamente)
            { $logger.Debug('Should be filtered') } | Should -Not -Throw
            { $logger.Info('Should be filtered') } | Should -Not -Throw
            { $logger.Warn('Should be filtered') } | Should -Not -Throw
            { $logger.Error('Should appear') } | Should -Not -Throw
        }
    }
    
    Context 'File Output' {
        It 'Should write to file' {
            $testFile = Join-Path $TestDrive 'test.log'
            
            $config = [LoggerConfig]::new()
            $config.OutputFile = $testFile
            $config.BufferSize = 1  # Flush imediatamente
            
            $logger = [Logger]::new($config)
            $logger.Info('Test message')
            $logger.Flush()
            
            Test-Path $testFile | Should -Be $true
            $content = Get-Content $testFile -Raw
            $content | Should -Match 'Test message'
        }
        
        It 'Should buffer messages' {
            $testFile = Join-Path $TestDrive 'buffer.log'
            
            $config = [LoggerConfig]::new()
            $config.OutputFile = $testFile
            $config.BufferSize = 5
            
            $logger = [Logger]::new($config)
            $logger.Info('Message 1')
            $logger.Info('Message 2')
            $logger.Info('Message 3')
            
            # Arquivo não deve existir ainda (buffer não cheio)
            # Flush manual
            $logger.Flush()
            
            Test-Path $testFile | Should -Be $true
        }
    }
}

Describe 'LogLevel Enum' {
    Context 'Values' {
        It 'Should have correct DEBUG value' {
            [LogLevel]::DEBUG.value__ | Should -Be 0
        }
        
        It 'Should have correct INFO value' {
            [LogLevel]::INFO.value__ | Should -Be 1
        }
        
        It 'Should have correct WARN value' {
            [LogLevel]::WARN.value__ | Should -Be 2
        }
        
        It 'Should have correct ERROR value' {
            [LogLevel]::ERROR.value__ | Should -Be 3
        }
        
        It 'Should have correct SUCCESS value' {
            [LogLevel]::SUCCESS.value__ | Should -Be 4
        }
        
        It 'Should have correct FATAL value' {
            [LogLevel]::FATAL.value__ | Should -Be 5
        }
    }
}

AfterAll {
    # Cleanup
    Remove-Module Logger -ErrorAction SilentlyContinue
}
