function ReadData([System.Net.Sockets.NetworkStream] $stream)
{
    [byte[]]$data = New-Object byte[] 1024
    $sb = New-Object Text.StringBuilder
    while ($stream.DataAvailable)
    {
        $stream.Read($data, 0, $data.Length)
        $sb.Append([text.Encoding]::UTF8.GetString($data))
    }
    return $sb.ToString();
}
$port=1709

$endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $port)
$listener = new-object System.Net.Sockets.TcpListener $endpoint
$listener.start()
$client = $listener.AcceptTcpClient()
Write-Host "Got connection from  ${$client.Client.RemoteEndPoint.AddressFamily} "
$stream = $client.GetStream()

while ($client.Connected)
{
    $data = ReadData($stream)
    Write-Host $data;
}