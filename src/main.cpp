#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QProcess>
#include <QStringList>
#include <QVariantMap>

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

    Q_INVOKABLE QVariantList installDisks() const
    {
        QProcess process;
        process.start(QStringLiteral("lsblk"), {QStringLiteral("-dnpo"), QStringLiteral("NAME,SIZE,MODEL,TYPE")});
        if (!process.waitForFinished(3000) || process.exitCode() != 0)
            return {};
        QVariantList disks;
        const auto lines = QString::fromUtf8(process.readAllStandardOutput()).split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QStringList fields = line.simplified().split(QLatin1Char(' '));
            if (fields.size() < 3 || fields.constLast() != QStringLiteral("disk"))
                continue;
            const QString device = fields.constFirst();
            const QString size = fields.value(1);
            const QString model = fields.mid(2, fields.size() - 3).join(QLatin1Char(' '));
            disks.append(QVariantMap{{QStringLiteral("device"), device},
                                     {QStringLiteral("label"), device + QStringLiteral("  •  ") + size + QStringLiteral("  •  ") + model}});
        }
        return disks;
    }

    Q_INVOKABLE bool launchInstaller(const QString &disk, const QString &confirmation)
    {
        if (!disk.startsWith(QStringLiteral("/dev/")) || confirmation.isEmpty())
            return false;
        return QProcess::startDetached(QStringLiteral("xterm"),
            {QStringLiteral("-T"), QStringLiteral("Install LokiOS"),
             QStringLiteral("-e"), QStringLiteral("sudo"),
             QStringLiteral("/usr/local/sbin/lokios-install"), disk, confirmation});
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
