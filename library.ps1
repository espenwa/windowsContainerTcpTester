function InitUtils($configFile) {
    $global:processId = [System.Diagnostics.Process]::GetCurrentProcess().Id

    # Define custom types
    Add-Type -TypeDefinition @"
    // Logging type enum
    public enum LogType
    {
        Verbose,
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
        Verbose { Write-Verbose $consoleMessage }
        Info { Write-Host $consoleMessage    }
        Warning { Write-Warning $consoleMessage    }
        Error { Write-Error $consoleMessage -ErrorAction Continue  }
    }
}

function ReadData([System.Net.Sockets.NetworkStream] $stream) {
    [byte[]]$data = New-Object byte[] 1024
    $sb = New-Object Text.StringBuilder
    do {
        try {
            $bytesRead = $stream.Read($data, 0, $data.Length)        
        }
        catch [System.IO.IOException] {
            return [String]::Empty
        }
        $sb.Append([text.Encoding]::UTF8.GetString($data, 0, $bytesRead)) | Out-Null
    } while ($stream.DataAvailable)
    return $($sb.ToString())
}

function createClient($config) {
    
    $ErrorActionPreference = "Stop"
    $endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $config.port)
    [System.Net.Sockets.TcpClient]$client = $Null

    if ($config.mode.Equals("Send")) {
        if ([string]::IsNullOrEmpty($config.targetHost))
        {
            Log Error "TargetHost is required when mode = Send"
            exit
        }
        $config.bytesToSend = [text.Encoding]::UTF8.GetBytes("ping`n");
        $config.stringToReceive = "pong`n";
        $config.sendFirst = $True;
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($config.targetHost, $config.port)
        Log Info "Connected to $($config.targetHost) : $($config.port)"
    }
    else {
        Log Info "Listening on $($config.port)"
        $config.bytesToSend = [text.Encoding]::UTF8.GetBytes("pong`n");
        $config.stringToReceive = "ping`n";
        $listener = new-object System.Net.Sockets.TcpListener $endpoint
        $listener.start()

        # Wait for pending connection
        while (-not $listener.Pending()) {
            if (CheckForExitKey) {
                Log Info "Q pressed - exiting"
                $listener.Stop()
                exit
            }
            Start-Sleep -Seconds 1
        }
        $client = $listener.AcceptTcpClient()
        Log Info "Got connection from $($client.Client.RemoteEndPoint.ToString())"
    }  
    $ErrorActionPreference = "Continue"
    return $client
}


InitUtils
