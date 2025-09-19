#ifndef MESSAGELISTENER_H
#define MESSAGELISTENER_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QList>
#include <QMap>

class MessageListener : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isListening READ isListening NOTIFY listeningStateChanged)
    Q_PROPERTY(quint16 port READ getPort NOTIFY listeningStateChanged)
    Q_PROPERTY(int clientCount READ getClientCount NOTIFY clientCountChanged)

public:
    explicit MessageListener(QObject *parent = nullptr);
    ~MessageListener();

    // 启动监听指定端口
    Q_INVOKABLE bool startListen(quint16 port);
    
    // 添加新的监听端口
    Q_INVOKABLE bool addListenPort(quint16 port);
    
    // 停止监听指定端口
    Q_INVOKABLE bool stopListenPort(quint16 port);
    
    // 停止监听所有端口
    Q_INVOKABLE void stopListen();
    
    // 获取当前监听状态
    bool isListening() const;
    
    // 获取所有监听的端口
    Q_INVOKABLE QList<int> getListeningPorts() const;
    
    // 获取主要监听的端口（第一个启动的端口）
    quint16 getPort() const;
    
    // 获取当前连接的客户端数量
    int getClientCount() const;
    
    // 向所有连接的客户端发送消息
    Q_INVOKABLE void sendMessageToAll(const QString &message);
    
    // 向指定端口的客户端发送消息
    Q_INVOKABLE void sendMessageToPort(quint16 port, const QString &message);
    
    // 向指定客户端发送消息
    void sendMessageToClient(QTcpSocket *client, const QString &message);

signals:
    // 收到新消息时发出
    void messageReceived(const QString &message, QTcpSocket *sender);
    
    // 新客户端连接时发出
    void clientConnected(QTcpSocket *client);
    
    // 客户端断开连接时发出
    void clientDisconnected(QTcpSocket *client);
    
    // 监听状态改变时发出
    void listeningStateChanged(bool isListening);
    
    // 客户端数量改变时发出
    void clientCountChanged(int count);
    
    // 端口监听状态改变时发出
    void portListeningStateChanged(quint16 port, bool listening);
    
    // 监听端口列表改变时发出
    void listeningPortsChanged(const QList<int> &ports);

private slots:
    // 处理新连接
    void onNewConnection();
    
    // 处理客户端数据
    void onClientDataReady();
    
    // 处理客户端断开连接
    void onClientDisconnected();

private:
    // 多端口服务器管理
    QMap<quint16, QTcpServer*> m_servers; // key: port, value: server
    QList<QTcpSocket*> m_clients;
    quint16 m_mainPort; // 主要端口（第一个启动的端口）
    
    // 获取客户端所在的端口
    quint16 getClientPort(QTcpSocket *client) const;
};

#endif // MESSAGELISTENER_H