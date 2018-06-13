function InitUtils($configFile) {
    $global:processId = [System.Diagnostics.Process]::GetCurrentProcess().Id

    # Define custom types
    Add-Type -TypeDefinition @"
    // Logging type enum
    public enum LogType
    {
        Debug,
        Info,
        Warning,
        Error
    }
"@
}

function CheckForExitKey() {
    while ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($True)
        if ($key.Key -eq [System.ConsoleKey]::Q) {
            return $true
        }
    }
    return $false
}

function Log([LogType]$logType = [LogType]::Info, $message) {
    $consoleMessage = "{0} : ({1}) : {2}" -f (Get-Date -format "yyyy-MM-dd HH:mm:ss"), $global:processId, $message
    switch ( $logType ) {
        Debug { Write-Debug $consoleMessage }
        Info { Write-Host $consoleMessage    }
        Warning { Write-Warning - $consoleMessage    }
        Error { Write-Error $consoleMessage -ErrorAction Continue  }
    }
}

InitUtils
