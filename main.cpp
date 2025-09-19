#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "messagelistener.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 创建消息监听器实例
    MessageListener *listener = new MessageListener(&app);

    QQmlApplicationEngine engine;
    
    // 将监听器注册到QML上下文中
    engine.rootContext()->setContextProperty("messageListener", listener);
    
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("simServer", "Main");

    return app.exec();
}
