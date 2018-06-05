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
    return $($sb.ToString().Trim(10))
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
$port = 1713

$endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $port)
$listener = new-object System.Net.Sockets.TcpListener $endpoint
$listener.start()
$client = $listener.AcceptTcpClient()
Write-Host "Got connection from  ${$client.Client.RemoteEndPoint.AddressFamily} "
$stream = $client.GetStream()
$stream.ReadTimeout = 5000

while ($client.Connected -and -not (CheckForExitKey))
{
    $readData = ReadData($stream)
    if ($readData -eq "ping")
    {
        Write-Host "Got ping!"
    }
    elseif ($readData)
    {
        Write-Host "Got data: $data";
    }
}

## Cleanup
$stream.Close();
$client.Close();
