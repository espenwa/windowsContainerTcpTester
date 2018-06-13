param(# Parameter help description
    [Parameter(Mandatory = $true)]
    [int] $TargetHost
    [Parameter(Mandatory = $true)]
    [int] $TargetPort
)
# Loading utils
. .\utils.ps1

Log Info "Quit by pressing 'q'"
Log Info
Log Info
$ErrorActionPreference = "Stop"
$endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $TargetPort)
$client = New-Object System.Net.Sockets.TcpClient
$client.Connect($TargetHost, $TargetPort)
$ErrorActionPreference = "Continue"

$stream = $client.GetStream()
$stream.ReadTimeout = 1000
$pingBytes = [text.Encoding]::UTF8.GetBytes("ping`n");
Log Info "Connected to $TargetHost on port $TargetPort"

# Timing setup
$firstPingReceivedAt = $null
$connectionReceivedAt = [DateTime]::Now
$lastPingReceivedAt = $null
$timeout = [TimeSpan]::FromSeconds(10)
$pingCount = 0
$runningTime = [timespan]::FromSeconds(0)

while ($client.Connected) {
    if (CheckForExitKey) {
        Log Info "Q pressed - exiting"
        break
    }
    # if ($lastPingReceivedAt -and ([DateTime]::Now - $lastPingReceivedAt -gt $timeout)) {
    #     Log Warning "Did not receive any ping within timeout threshold, exiting"
    #     break
    # }

    $receivedData = ReadData($stream)

    if ($receivedData -eq "ping`n") {
        $lastPingReceivedAt = [DateTime]::Now
        if (-not $firstPingReceivedAt) {
            $firstPingReceivedAt = $lastPingReceivedAt
            Log Info "First ping received"
        }
        $pingCount++
        $stream.Write($pongBytes, 0, $pongBytes.Length)
    }
    elseif ($receivedData) {
        Log Warning "Got unrecognized data : $receivedData";
    }
    
    $currentRunningTime = [DateTime]::Now - $connectionReceivedAt
    if (($currentRunningTime - $runningTime).TotalMinutes -gt 1) {
        $runningTime = $currentRunningTime
        Log Info "Current running time $currentRunningTime"
    }
}

Log Info "Connection : " $connectionReceivedAt
Log Info "First ping : " $firstPingReceivedAt
Log Info "Last ping : " $lastPingReceivedAt
Log Info "Number of pings : " $pingCount

## Cleanup
$stream.Close();
$client.Close();
$listener.Stop();