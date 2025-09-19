# TCP多端口消息监听器

这是一个基于Qt的TCP消息监听器，支持同时监听多个端口的服务器功能。

## 功能特性

### 1. 多端口TCP服务器功能
- 同时监听多个端口
- 动态添加和删除监听端口
- 支持多客户端同时连接
- 实时显示所有监听端口和连接数量
- 接收并显示各端口客户端消息

### 2. 消息管理功能
- 向所有端口的所有客户端广播消息
- 向指定端口的客户端发送消息
- 实时接收和显示来自不同端口的消息
- 消息颜色编码区分不同来源

### 3. 用户界面
- 直观的多端口管理面板
- 实时状态显示（监听端口、客户端数量）
- 消息历史记录查看
- 清除消息记录功能

## 使用方法

### 启动监听第一个端口
1. 在端口输入框输入端口号（如8080）
2. 点击"开始监听"按钮
3. 状态会显示"正在监听端口 8080"

### 添加更多监听端口
1. 在"多端口管理"面板中输入新端口号（如8081）
2. 点击"添加监听"按钮
3. 系统会同时监听多个端口

### 停止指定端口监听
1. 在"要停止的端口号"输入框输入端口
2. 点击"停止端口"按钮
3. 指定端口将停止监听

### 发送消息
- **向所有端口客户端发送**: 在上方消息框输入内容，点击"发送给所有客户端"
- **向指定端口发送**: 在下方消息框输入内容，先输入目标端口，再点击"发送"

### 消息颜色说明
- **蓝色**: 服务器发送的消息
- **黑色**: 客户端发送的消息
- **绿色**: 系统连接消息
- **橙色**: 系统断开消息
- **紫色**: 发送到指定端口的消息
- **红色**: 错误消息
- **灰色**: 系统提示消息

## 测试功能

### 使用内置测试服务器
```powershell
# 启动测试服务器（监听端口8081）
PowerShell -ExecutionPolicy Bypass -File test_server.ps1

# 或指定端口
PowerShell -ExecutionPolicy Bypass -File test_server.ps1 -Port 8082
```

### 使用telnet测试
```cmd
# 连接到本地服务器的不同端口
telnet localhost 8080
telnet localhost 8081

# 然后可以输入消息进行测试
```

### 多端口测试示例
```powershell
# 窗口 1: 连接到端口 8080
$client1 = New-Object System.Net.Sockets.TcpClient
$client1.Connect("localhost", 8080)
$stream1 = $client1.GetStream()
$writer1 = New-Object System.IO.StreamWriter($stream1)
$writer1.WriteLine("来自端口 8080 的消息!")
$writer1.Flush()

# 窗口 2: 连接到端口 8081
$client2 = New-Object System.Net.Sockets.TcpClient
$client2.Connect("localhost", 8081)
$stream2 = $client2.GetStream()
$writer2 = New-Object System.IO.StreamWriter($stream2)
$writer2.WriteLine("来自端口 8081 的消息!")
$writer2.Flush()
```

## 编译运行

### 环境要求
- Qt 6.8 或更高版本
- CMake 3.16 或更高版本
- 支持C++标准的编译器

### 编译步骤
```bash
mkdir build
cd build
cmake ..
cmake --build .
```

### 运行程序
```bash
# Windows
.\simServer.exe

# 或直接双击生成的可执行文件
```

## 技术架构

### 核心类: MessageListener
- **继承**: QObject
- **功能**: 管理TCP服务器和客户端连接
- **信号**: 
  - `messageReceived`: 接收到消息
  - `clientConnected/clientDisconnected`: 客户端连接状态
  - `clientConnectionStateChanged`: 外部连接状态
  - `messageReceivedFromHost`: 来自外部主机的消息

### QML界面
- **文件**: Main.qml
- **功能**: 提供用户交互界面
- **组件**: 控制面板、消息显示、连接管理

## 故障排除

### 常见问题
1. **端口被占用**: 尝试使用其他端口号
2. **防火墙阻止**: 检查Windows防火墙设置
3. **连接失败**: 确认目标服务器正在运行且端口正确

### 调试模式
程序会在控制台输出详细的调试信息，包括：
- 连接状态变化
- 消息发送接收
- 错误信息

## 扩展功能

可以进一步添加的功能：
- SSL/TLS加密连接
- 用户认证
- 文件传输
- 心跳检测
- 连接重试机制
- 消息加密