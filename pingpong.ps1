param(
    [Parameter(Mandatory = $true)]
    [int] $Port,
    [string] $TargetHost,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Send", "Listen")]
    [string]$Mode
)
# Loading utils
. .\library.ps1

$config = @{
    port         = $Port;
    targetHost   = $TargetHost;
    dataToSend   = "";
    dataToExpect = "";
    sendFirst    = $False;
    mode         = $Mode;
    sendPause    = [TimeSpan]::FromSeconds(5);
}

Log Info "Quit by pressing 'q'"
Log Info
Log Info

$client = createClient($config)
$stream = $client.GetStream()
$stream.ReadTimeout = 1000

# Timing setup
$statistics = @{
    firstPingReceivedAt  = $null;
    connectionReceivedAt = [DateTime]::Now;
    lastPingReceivedAt   = $null;
    timeout              = [TimeSpan]::FromSeconds(20);
    pingCount            = 0;
    runningTime          = [timespan]::FromSeconds(0);
}

if ($config.sendFirst)
{
    $stream.Write($config.bytesToSend, 0, $config.bytesToSend.Length)
}

while ($True) {
    if (CheckForExitKey) {
        Log Info "Q pressed - exiting"
        break
    }
    if ($statistics.lastPingReceivedAt -and ([DateTime]::Now - $statistics.lastPingReceivedAt -gt $statistics.timeout)) {
        Log Warning "Did not receive exptected data within timeout threshold, exiting"
        break
    }

    $receivedData = ReadData($stream)

    if ($receivedData -eq $config.stringToReceive) {
        $statistics.lastPingReceivedAt = [DateTime]::Now
        if (-not $statistics.firstPingReceivedAt) {
            $statistics.firstPingReceivedAt = $statistics.lastPingReceivedAt
            Log Info "First data received"
        }
        else {
            Log Verbose "Got data"
        }
        $statistics.pingCount++
        $stream.Write($config.bytesToSend, 0, $config.bytesToSend.Length)
    }
    elseif ($receivedData) {
        Log Warning "Got unrecognized data : $receivedData";
    }
    
    $statistics.currentRunningTime = [DateTime]::Now - $statistics.connectionReceivedAt
    if (($statistics.currentRunningTime - $statistics.runningTime).TotalMinutes -gt 1) {
        $statistics.runningTime = $statistics.currentRunningTime
        Log Info "Current running time $($statistics.currentRunningTime)"
    }
    if ($config.sendFirst)
    {
        [System.Threading.Thread]::Sleep($config.sendPause)
    }
}

Log Info "Connected at : $($statistics.connectionReceivedAt)"
Log Info "First valid data received at : $($statistics.firstPingReceivedAt)"
Log Info "Last valid data received at : $($statistics.lastPingReceivedAt)"
Log Info "Number of pings : $($statistics.pingCount)"

## Cleanup
$stream.Close();
$client.Close();
#$listener.Stop();