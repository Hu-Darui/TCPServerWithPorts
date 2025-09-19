#include "messagelistener.h"
#include <QDebug>

MessageListener::MessageListener(QObject *parent)
    : QObject(parent)
    , m_mainPort(0)
{
    // 不需要在构造函数中创建服务器，将在startListen中创建
}

MessageListener::~MessageListener()
{
    stopListen();
}

bool MessageListener::startListen(quint16 port)
{
    return addListenPort(port);
}

bool MessageListener::addListenPort(quint16 port)
{
    // 检查是否已经在监听这个端口
    if (m_servers.contains(port)) {
        qWarning() << "Port" << port << "is already being listened";
        return false;
    }

    // 创建新的TCP服务器
    QTcpServer *server = new QTcpServer(this);
    
    // 连接服务器信号
    connect(server, &QTcpServer::newConnection, this, &MessageListener::onNewConnection);
    
    // 尝试启动监听
    if (server->listen(QHostAddress::Any, port)) {
        m_servers[port] = server;
        
        // 设置主要端口（第一个启动的端口）
        if (m_mainPort == 0) {
            m_mainPort = port;
        }
        
        qInfo() << "Server started listening on port" << port;
        emit portListeningStateChanged(port, true);
        emit listeningStateChanged(isListening());
        emit listeningPortsChanged(getListeningPorts());
        return true;
    } else {
        qWarning() << "Failed to start server on port" << port << ":" << server->errorString();
        server->deleteLater();
        return false;
    }
}

bool MessageListener::stopListenPort(quint16 port)
{
    if (!m_servers.contains(port)) {
        qWarning() << "Port" << port << "is not being listened";
        return false;
    }
    
    QTcpServer *server = m_servers[port];
    server->close();
    server->deleteLater();
    m_servers.remove(port);
    
    // 如果停止的是主要端口，更新主要端口
    if (m_mainPort == port) {
        if (!m_servers.isEmpty()) {
            m_mainPort = m_servers.firstKey();
        } else {
            m_mainPort = 0;
        }
    }
    
    qInfo() << "Stopped listening on port" << port;
    emit portListeningStateChanged(port, false);
    emit listeningStateChanged(isListening());
    emit listeningPortsChanged(getListeningPorts());
    return true;
}

void MessageListener::stopListen()
{
    // 断开所有客户端连接
    for (QTcpSocket *client : m_clients) {
        client->disconnectFromHost();
        client->deleteLater();
    }
    m_clients.clear();
    
    // 关闭所有服务器
    for (auto it = m_servers.begin(); it != m_servers.end(); ++it) {
        QTcpServer *server = it.value();
        server->close();
        server->deleteLater();
    }
    m_servers.clear();
    
    m_mainPort = 0;
    qInfo() << "All servers stopped listening";
    emit listeningStateChanged(false);
    emit listeningPortsChanged(getListeningPorts());
}

bool MessageListener::isListening() const
{
    return !m_servers.isEmpty();
}

QList<int> MessageListener::getListeningPorts() const
{
    QList<int> ports;
    for (auto it = m_servers.begin(); it != m_servers.end(); ++it) {
        ports.append(it.key());
    }
    return ports;
}

quint16 MessageListener::getPort() const
{
    return m_mainPort;
}

int MessageListener::getClientCount() const
{
    return m_clients.count();
}

void MessageListener::sendMessageToAll(const QString &message)
{
    QByteArray data = message.toUtf8() + "\n";
    for (QTcpSocket *client : m_clients) {
        if (client->state() == QTcpSocket::ConnectedState) {
            client->write(data);
            client->flush();
        }
    }
    qDebug() << "Sent message to all clients:" << message;
}

void MessageListener::sendMessageToPort(quint16 port, const QString &message)
{
    QByteArray data = message.toUtf8() + "\n";
    int count = 0;
    
    for (QTcpSocket *client : m_clients) {
        if (client->state() == QTcpSocket::ConnectedState && getClientPort(client) == port) {
            client->write(data);
            client->flush();
            count++;
        }
    }
    qDebug() << "Sent message to" << count << "clients on port" << port << ":" << message;
}

void MessageListener::sendMessageToClient(QTcpSocket *client, const QString &message)
{
    if (client && client->state() == QTcpSocket::ConnectedState) {
        QByteArray data = message.toUtf8() + "\n";
        client->write(data);
        client->flush();
        qDebug() << "Sent message to client:" << message;
    }
}

void MessageListener::onNewConnection()
{
    // 找到发起连接的服务器
    QTcpServer *server = qobject_cast<QTcpServer*>(sender());
    if (!server) return;
    
    while (server->hasPendingConnections()) {
        QTcpSocket *client = server->nextPendingConnection();
        m_clients.append(client);
        
        // 存储客户端所连接的端口信息
        quint16 serverPort = server->serverPort();
        client->setProperty("serverPort", serverPort);
        
        // 连接客户端信号
        connect(client, &QTcpSocket::readyRead, this, &MessageListener::onClientDataReady);
        connect(client, &QTcpSocket::disconnected, this, &MessageListener::onClientDisconnected);
        
        qInfo() << "New client connected to port" << serverPort 
                << "from" << client->peerAddress().toString() 
                << ":" << client->peerPort();
        
        emit clientConnected(client);
        emit clientCountChanged(m_clients.count());
    }
}

void MessageListener::onClientDataReady()
{
    QTcpSocket *client = qobject_cast<QTcpSocket*>(sender());
    if (!client) return;
    
    while (client->canReadLine()) {
        QByteArray data = client->readLine();
        QString message = QString::fromUtf8(data).trimmed();
        
        if (!message.isEmpty()) {
            quint16 serverPort = client->property("serverPort").toUInt();
            qInfo() << "Received message on port" << serverPort 
                    << "from" << client->peerAddress().toString() 
                    << ":" << message;
            emit messageReceived(message, client);
        }
    }
}

void MessageListener::onClientDisconnected()
{
    QTcpSocket *client = qobject_cast<QTcpSocket*>(sender());
    if (!client) return;
    
    m_clients.removeOne(client);
    client->deleteLater();
    
    quint16 serverPort = client->property("serverPort").toUInt();
    qInfo() << "Client disconnected from port" << serverPort 
            << "from" << client->peerAddress().toString();
    emit clientDisconnected(client);
    emit clientCountChanged(m_clients.count());
}

quint16 MessageListener::getClientPort(QTcpSocket *client) const
{
    if (client) {
        return client->property("serverPort").toUInt();
    }
    return 0;
}