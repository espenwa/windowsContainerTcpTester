function ReadData([System.Net.Sockets.NetworkStream] $stream)
{
    [byte[]]$data = New-Object byte[] 1024
    $sb = New-Object Text.StringBuilder
    do
    {
        try {
            $bytesRead = $stream.Read($data, 0, $data.Length)        
        }
        catch [System.IO.IOException] {
            return [String]::Empty
        }
        $sb.Append([text.Encoding]::UTF8.GetString($data, 0, $bytesRead)) | Out-Null
    } while ($stream.DataAvailable)
    return $($sb.ToString().Trim(10))
}
$port=1716

$endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $port)
$listener = new-object System.Net.Sockets.TcpListener $endpoint
$listener.start()
$client = $listener.AcceptTcpClient()
Write-Host "Got connection from  ${$client.Client.RemoteEndPoint.AddressFamily} "
$stream = $client.GetStream()
$stream.ReadTimeout = 5000
while ($client.Connected)
{
    $readData = ReadData($stream)
    if ($readData -eq "ping")
    {
        Write-Host "Got ping!"
    }
    else {
        Write-Host "Got data: $data";
    }
    if ([Console]::KeyAvailable)
    {
        $stream.Close();
        $client.Close();
    }
}