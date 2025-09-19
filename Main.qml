import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "TCP消息监听器"
    
    property bool isListening: false
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10
        
        // 标题
        Text {
            text: "TCP消息监听服务器"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        // 状态显示面板
        Rectangle {
            Layout.fillWidth: true
            height: 60
            border.color: "#cccccc"
            border.width: 1
            radius: 5
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 20
                
                Text {
                    id: statusText
                    text: "未监听"
                    font.pixelSize: 14
                    color: "gray"
                    Layout.fillWidth: true
                }
                
                Text {
                    id: clientCountText
                    text: "连接数: 0"
                    font.pixelSize: 14
                    color: "blue"
                }
                
                Text {
                    text: "监听端口:"
                    font.pixelSize: 14
                }
                
                Text {
                    id: listeningPortsDisplay
                    text: "无"
                    font.pixelSize: 14
                    color: "blue"
                }
                
                Button {
                    text: "停止所有"
                    Layout.preferredWidth: 80
                    enabled: isListening
                    
                    onClicked: {
                        messageListener.stopListen()
                        addMessage("系统", "已停止所有端口监听", "orange")
                    }
                }
            }
        }
        
        // 消息发送面板
        Rectangle {
            Layout.fillWidth: true
            height: 60
            border.color: "#cccccc"
            border.width: 1
            radius: 5
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                
                TextField {
                    id: messageField
                    placeholderText: "输入要发送的消息..."
                    Layout.fillWidth: true
                    
                    onAccepted: sendButton.clicked()
                }
                
                Button {
                    id: sendButton
                    text: "发送给所有客户端"
                    enabled: isListening
                    
                    onClicked: {
                        if (messageField.text.length > 0) {
                            messageListener.sendMessageToAll(messageField.text)
                            addMessage("服务器", messageField.text, "blue")
                            messageField.text = ""
                        }
                    }
                }
            }
        }
        
        // 客户端连接面板 - 更改为多端口管理
        Rectangle {
            Layout.fillWidth: true
            height: 120
            border.color: "#cccccc"
            border.width: 1
            radius: 5
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5
                
                Text {
                    text: "多端口管理:"
                    font.pixelSize: 14
                    font.bold: true
                }
                
                RowLayout {
                    spacing: 10
                    
                    Text {
                        text: "新端口:"
                        font.pixelSize: 12
                    }
                    
                    TextField {
                        id: newPortField
                        text: "8081"
                        placeholderText: "端口号"
                        validator: IntValidator { bottom: 1024; top: 65535 }
                        Layout.preferredWidth: 80
                    }
                    
                    Button {
                        text: "添加监听"
                        Layout.preferredWidth: 80
                        
                        onClicked: {
                            var port = parseInt(newPortField.text)
                            if (port >= 1024 && port <= 65535) {
                                if (messageListener.addListenPort(port)) {
                                    addMessage("系统", "已添加监听端口 " + port, "green")
                                    newPortField.text = (port + 1).toString()
                                } else {
                                    addMessage("系统", "添加端口 " + port + " 失败，可能已被占用", "red")
                                }
                            } else {
                                addMessage("系统", "请输入有效的端口号 (1024-65535)", "red")
                            }
                        }
                    }
                }
                
                RowLayout {
                    spacing: 10
                    
                    TextField {
                        id: portToStopField
                        placeholderText: "要停止的端口号"
                        validator: IntValidator { bottom: 1024; top: 65535 }
                        Layout.preferredWidth: 120
                    }
                    
                    Button {
                        text: "停止端口"
                        Layout.preferredWidth: 80
                        
                        onClicked: {
                            var port = parseInt(portToStopField.text)
                            if (port >= 1024 && port <= 65535) {
                                if (messageListener.stopListenPort(port)) {
                                    addMessage("系统", "已停止监听端口 " + port, "orange")
                                    portToStopField.text = ""
                                } else {
                                    addMessage("系统", "端口 " + port + " 未在监听", "red")
                                }
                            } else {
                                addMessage("系统", "请输入有效的端口号", "red")
                            }
                        }
                    }
                    
                    TextField {
                        id: portMessageField
                        placeholderText: "向指定端口发送消息..."
                        Layout.fillWidth: true
                        
                        onAccepted: sendToPortButton.clicked()
                    }
                    
                    Button {
                        id: sendToPortButton
                        text: "发送"
                        Layout.preferredWidth: 60
                        
                        onClicked: {
                            var port = parseInt(portToStopField.text)
                            var message = portMessageField.text.trim()
                            
                            if (port >= 1024 && port <= 65535 && message.length > 0) {
                                messageListener.sendMessageToPort(port, message)
                                addMessage("发送到端口 " + port, message, "purple")
                                portMessageField.text = ""
                            } else {
                                addMessage("系统", "请输入有效的端口号和消息", "red")
                            }
                        }
                    }
                }
            }
        }
        
        // 消息显示区域
        Text {
            text: "接收到的消息:"
            font.pixelSize: 16
            font.bold: true
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            border.color: "#cccccc"
            border.width: 1
            radius: 5
            
            ScrollView {
                anchors.fill: parent
                anchors.margins: 5
                
                ListView {
                    id: messageListView
                    model: messageModel
                    spacing: 2
                    
                    delegate: Rectangle {
                        width: messageListView.width
                        height: messageText.contentHeight + 10
                        color: index % 2 === 0 ? "#f5f5f5" : "#ffffff"
                        radius: 3
                        
                        Text {
                            id: messageText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 8
                            
                            text: "[" + model.time + "] " + model.sender + ": " + model.message
                            color: model.textColor
                            wrapMode: Text.Wrap
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
        
        // 清除按钮
        Button {
            text: "清除消息记录"
            Layout.alignment: Qt.AlignHCenter
            
            onClicked: {
                messageModel.clear()
            }
        }
    }
    
    // 消息模型
    ListModel {
        id: messageModel
    }
    
    // 连接MessageListener的信号
    Connections {
        target: messageListener
        
        function onMessageReceived(message, sender) {
            var clientInfo = "客户端(" + sender.peerAddress + ":" + sender.peerPort + ")"
            addMessage(clientInfo, message, "black")
        }
        
        function onClientConnected(client) {
            var clientInfo = "客户端(" + client.peerAddress + ":" + client.peerPort + ")"
            addMessage("系统", clientInfo + " 已连接", "green")
            updateClientCount()
        }
        
        function onClientDisconnected(client) {
            var clientInfo = "客户端(" + client.peerAddress + ":" + client.peerPort + ")"
            addMessage("系统", clientInfo + " 已断开连接", "orange")
            updateClientCount()
        }
        
        function onListeningStateChanged(listening) {
            isListening = listening
            if (listening) {
                statusText.text = "正在监听多个端口"
                statusText.color = "green"
            } else {
                statusText.text = "未监听"
                statusText.color = "gray"
            }
        }
        
        function onClientCountChanged(count) {
            clientCountText.text = "连接数: " + count
        }
        
        function onPortListeningStateChanged(port, listening) {
            var status = listening ? "已启动" : "已停止"
            var color = listening ? "green" : "orange"
            addMessage("系统", "端口 " + port + " " + status + " 监听", color)
        }
        
        function onListeningPortsChanged(ports) {
            if (ports.length === 0) {
                listeningPortsDisplay.text = "无"
                statusText.text = "未监听"
                statusText.color = "gray"
                clientCountText.text = "连接数: 0"
            } else {
                listeningPortsDisplay.text = ports.join(", ")
                statusText.text = "正在监听 " + ports.length + " 个端口"
                statusText.color = "green"
            }
        }
    }
    
    // 添加消息到列表
    function addMessage(sender, message, textColor) {
        var now = new Date()
        var timeString = Qt.formatTime(now, "hh:mm:ss")
        
        messageModel.append({
            time: timeString,
            sender: sender,
            message: message,
            textColor: textColor || "black"
        })
        
        // 自动滚动到底部
        messageListView.positionViewAtEnd()
        
        // 限制消息数量，避免内存占用过多
        if (messageModel.count > 1000) {
            messageModel.remove(0, 100)
        }
    }
    
    Component.onCompleted: {
        addMessage("系统", "TCP多端口消息监听器已启动", "blue")
        addMessage("系统", "可以同时监听多个端口，在上方输入端口号并点击'添加监听'", "gray")
    }
}