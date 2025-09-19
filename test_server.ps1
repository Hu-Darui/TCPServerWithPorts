# TCP测试服务器脚本 (PowerShell)
# 用于测试客户端连接功能

param(
    [int]$Port = 8081
)

Write-Host "启动TCP测试服务器，监听端口 $Port..."
Write-Host "使用 Ctrl+C 停止服务器"

# 创建TCP监听器
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
$listener.Start()

Write-Host "服务器已启动，等待连接..."

try {
    while ($true) {
        # 等待客户端连接
        $client = $listener.AcceptTcpClient()
        $clientEndpoint = $client.Client.RemoteEndPoint
        Write-Host "客户端已连接: $clientEndpoint"
        
        # 获取数据流
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $writer = [System.IO.StreamWriter]::new($stream)
        
        # 发送欢迎消息
        $writer.WriteLine("欢迎连接到测试服务器!")
        $writer.Flush()
        
        # 在后台处理客户端
        $job = Start-Job -ScriptBlock {
            param($clientStream, $clientEndpoint)
            
            $reader = [System.IO.StreamReader]::new($clientStream)
            $writer = [System.IO.StreamWriter]::new($clientStream)
            
            try {
                while ($clientStream.Connected) {
                    # 读取消息
                    $message = $reader.ReadLine()
                    if ($message -eq $null) { break }
                    
                    Write-Host "收到来自 $clientEndpoint 的消息: $message"
                    
                    # 回复消息
                    $reply = "服务器收到: $message"
                    $writer.WriteLine($reply)
                    $writer.Flush()
                }
            }
            catch {
                Write-Host "客户端 $clientEndpoint 连接异常: $($_.Exception.Message)"
            }
            finally {
                $reader.Close()
                $writer.Close()
                $clientStream.Close()
                Write-Host "客户端 $clientEndpoint 已断开连接"
            }
        } -ArgumentList $stream, $clientEndpoint
    }
}
catch {
    Write-Host "服务器异常: $($_.Exception.Message)"
}
finally {
    $listener.Stop()
    Write-Host "服务器已停止"
}