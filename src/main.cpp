#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("LokiOS");
    app.setOrganizationName("LokiOS");

    QQmlApplicationEngine engine;
    engine.loadFromModule("LokiOS", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
