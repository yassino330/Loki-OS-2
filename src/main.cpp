#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QProcess>
#include <QStringList>

class SystemActions final : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;

    Q_INVOKABLE bool launch(const QString &program)
    {
        static const QStringList allowed{
            QStringLiteral("pcmanfm"),
            QStringLiteral("xterm"),
            QStringLiteral("lxappearance"),
            QStringLiteral("xfce4-terminal")
        };
        if (!allowed.contains(program))
            return false;
        return QProcess::startDetached(program, {});
    }

    Q_INVOKABLE bool launchInstaller()
    {
        return QProcess::startDetached(QStringLiteral("xterm"), {QStringLiteral("-T"), QStringLiteral("Install LokiOS"), QStringLiteral("-e"), QStringLiteral("sudo"), QStringLiteral("/usr/local/sbin/lokios-install")});
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("LokiOS"));
    app.setOrganizationName(QStringLiteral("LokiOS"));

    SystemActions actions;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("SystemActions"), &actions);
    engine.loadFromModule("LokiOS", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

#include "main.moc"
