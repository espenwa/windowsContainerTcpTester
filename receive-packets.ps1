function ReadData([System.Net.Sockets.NetworkStream] $stream)
{
    [byte[]]$data = New-Object byte[] 1024
    $sb = New-Object Text.StringBuilder
    do
    {
        try
        {
            $bytesRead = $stream.Read($data, 0, $data.Length)        
        }
        catch [System.IO.IOException]
        {
            return [String]::Empty
        }
        $sb.Append([text.Encoding]::UTF8.GetString($data, 0, $bytesRead)) | Out-Null
    } while ($stream.DataAvailable)
    return $($sb.ToString())
}

function CheckForExitKey()
{
    while ([Console]::KeyAvailable)
    {
        $key = [Console]::ReadKey()
        if ($key.Key -eq [System.ConsoleKey]::Q)
        {
            return $true
        }
    }
    return $false
}

$port = 1710

$endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $port)
$listener = new-object System.Net.Sockets.TcpListener $endpoint
$listener.start()

# Wait for pending connection
while (-not $listener.Pending())
{
  if (CheckForExitKey)
  {
      Write-Host "Q pressed - exiting"
      $listener.Stop()
      exit
  }
  Start-Sleep -Seconds 1
}

$client = $listener.AcceptTcpClient()
$stream = $client.GetStream()
$stream.ReadTimeout = 1000
$pongBytes = [text.Encoding]::UTF8.GetBytes("pong`n");
Write-Host "Got connection from $($client.Client.RemoteEndPoint.ToString())"


# Timing setup
$firstPingReceivedAt = $null
$connectionReceivedAt = [DateTime]::Now
$lastPingReceivedAt = $null
$timeout = [TimeSpan]::FromSeconds(10)
$pingCount = 0
$runningTime = [timespan]::FromSeconds(0)

while ($client.Connected)
{
    if (CheckForExitKey)
    {
        Write-Host "Q pressed - exiting"
        break
    }
    if ($lastPingReceivedAt -and ([DateTime]::Now - $lastPingReceivedAt -gt $timeout))
    {
        Write-Host "Did not receive any ping within timeout threshold, exiting"
        break
    }

    $receivedData = ReadData($stream)

    if ($receivedData -eq "ping`n")
    {
        $lastPingReceivedAt = [DateTime]::Now
        if (-not $firstPingReceivedAt)
        {
            $firstPingReceivedAt = $lastPingReceivedAt
            Write-Host "First ping received"
        }
        $pingCount++
        $stream.Write($pongBytes, 0, $pongBytes.Length)
    }
    elseif ($receivedData)
    {
        Write-Host "Got unrecognized data : $receivedData";
    }
    $currentRunningTime = [DateTime]::Now - $connectionReceivedAt
    if (($currentRunningTime - $runningTime).TotalMinutes -gt 1)
    {
        $runningTime = $currentRunningTime
        Write-Host "Current running time $currentRunningTime"
    }
}

Write-Host "Connection : " $connectionReceivedAt
Write-Host "First ping : " $firstPingReceivedAt
Write-Host "Last ping : " $lastPingReceivedAt
Write-HOst "Number of pings : " $pingCount

## Cleanup
$stream.Close();
$client.Close();
$listener.Stop();