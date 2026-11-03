#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QProcess>

class SystemActions final : public QObject
{
    Q_OBJECT

public:
    using QObject::QObject;

    Q_INVOKABLE bool launch(const QString &program)
    {
        // Commands are fixed by the LokiOS shell UI, never user-supplied shell text.
        return QProcess::startDetached(program, QStringList{});
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("LokiOS");
    app.setOrganizationName("LokiOS");

    SystemActions actions;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("SystemActions", &actions);
    engine.loadFromModule("LokiOS", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

#include "main.moc"
