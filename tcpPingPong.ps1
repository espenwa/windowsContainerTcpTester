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
    timeout      = [TimeSpan]::FromSeconds(30);
}

Log Info "Quit by pressing 'q'"
Log Info "Usage: tcpPingPong -Port <portNumber> -Mode [Listen|Send] -TargetHost <targetHost>"
Log Info
Log Info "TargetHost is only needed when in 'Send'-mode'"
Log Info

$client = createClient($config)
$stream = $client.GetStream()
$stream.ReadTimeout = 1000

# Timing setup
$statistics = @{
    firstPingReceivedAt  = $null;
    connectionReceivedAt = [DateTime]::Now;
    lastPingReceivedAt   = $null;
    pingCount            = 0;
    runningTime          = [timespan]::FromSeconds(0);
}

if ($config.sendFirst)
{
    $stream.Write($config.bytesToSend, 0, $config.bytesToSend.Length)
    Log Verbose "Sendt first data"
}

while ($True) {
    if (CheckForExitKey) {
        Log Info "Q pressed - exiting"
        break
    }
    if ($statistics.lastPingReceivedAt -and ([DateTime]::Now - $statistics.lastPingReceivedAt -gt $config.timeout)) {
        Log Warning "Did not receive expected data within timeout threshold, exiting"
        break
    }

    $receivedData = ReadData($stream)

    if ($receivedData -eq $config.stringToReceive) {
        $statistics.lastPingReceivedAt = [DateTime]::Now
        Log Verbose "Got expected data"

        if (-not $statistics.firstPingReceivedAt) {
            $statistics.firstPingReceivedAt = $statistics.lastPingReceivedAt
            Log Info "First data received"
        }

        $statistics.pingCount++
        $stream.Write($config.bytesToSend, 0, $config.bytesToSend.Length)
        Log Verbose "Sendt data"
    }
    elseif ($receivedData) {
        Log Warning "Got unrecognized data : $receivedData";
    }
    
    $statistics.currentRunningTime = [DateTime]::Now - $statistics.connectionReceivedAt
    if (($statistics.currentRunningTime - $statistics.runningTime).TotalMinutes -gt 1) {
        $statistics.runningTime = $statistics.currentRunningTime
        Log Info "Current running time $($statistics.currentRunningTime) - $($statistics.pingCount) pings"
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