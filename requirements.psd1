@{
    # PSResourceGet requirements file for Logger module
    # Install dependencies: Install-PSResource -RequiredResourceFile requirements.psd1
    
    # Core dependencies for development and testing
    PSDependencies = @{
        # Testing framework
        'Pester' = @{
            Version = '[5.0.0,6.0.0)'
            Repository = 'PSGallery'
            Target = 'CurrentUser'
        }
        
        # Code quality and analysis
        'PSScriptAnalyzer' = @{
            Version = '[1.21.0,2.0.0)'
            Repository = 'PSGallery'
            Target = 'CurrentUser'
        }
    }
}
