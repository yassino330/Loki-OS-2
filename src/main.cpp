#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QProcess>
#include <QStringList>
#include <QVariantMap>

class SystemActions final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString installerOutput READ installerOutput NOTIFY installerOutputChanged)
    Q_PROPERTY(bool installerRunning READ installerRunning NOTIFY installerRunningChanged)
    Q_PROPERTY(QString installerStatus READ installerStatus NOTIFY installerStatusChanged)
public:
    using QObject::QObject;

    QString installerOutput() const { return m_output; }
    bool installerRunning() const { return m_installer.state() != QProcess::NotRunning; }
    QString installerStatus() const { return m_status; }

    Q_INVOKABLE bool launch(const QString &program)
    {
        static const QStringList allowed{
            QStringLiteral("pcmanfm"), QStringLiteral("xterm"),
            QStringLiteral("lxappearance"), QStringLiteral("xfce4-terminal"), QStringLiteral("chromium")
        };
        if (!allowed.contains(program)) return false;
        return QProcess::startDetached(program, {});
    }

    Q_INVOKABLE QVariantList installDisks() const
    {
        QProcess process;
        process.start(QStringLiteral("lsblk"), {QStringLiteral("-dnpo"), QStringLiteral("NAME,SIZE,MODEL,TYPE")});
        if (!process.waitForFinished(3000) || process.exitCode() != 0) return {};
        QVariantList disks;
        const auto lines = QString::fromUtf8(process.readAllStandardOutput()).split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QStringList fields = line.simplified().split(QLatin1Char(' '));
            if (fields.size() < 3 || fields.constLast() != QStringLiteral("disk")) continue;
            const QString device = fields.constFirst();
            const QString size = fields.value(1);
            const QString model = fields.mid(2, fields.size() - 3).join(QLatin1Char(' '));
            disks.append(QVariantMap{{QStringLiteral("device"), device},
                                     {QStringLiteral("label"), device + QStringLiteral("  •  ") + size + QStringLiteral("  •  ") + model}});
        }
        return disks;
    }

    Q_INVOKABLE bool startInstaller(const QString &disk, const QString &confirmation)
    {
        if (installerRunning() || !disk.startsWith(QStringLiteral("/dev/")) ||
            confirmation != QStringLiteral("ERASE ") + disk.section(QLatin1Char('/'), -1))
            return false;
        m_output.clear();
        setStatus(QStringLiteral("Preparing installation…"));
        emit installerOutputChanged();
        m_installer.start(QStringLiteral("sudo"),
            {QStringLiteral("-n"), QStringLiteral("/usr/local/sbin/lokios-install"), disk, confirmation});
        return true;
    }

signals:
    void installerOutputChanged();
    void installerRunningChanged();
    void installerStatusChanged();

private:
    void setStatus(const QString &status)
    {
        if (m_status == status) return;
        m_status = status;
        emit installerStatusChanged();
    }

    QString m_output;
    QString m_status = QStringLiteral("Ready");
    QProcess m_installer;

private slots:
    void appendInstallerOutput()
    {
        m_output += QString::fromUtf8(m_installer.readAllStandardOutput());
        m_output += QString::fromUtf8(m_installer.readAllStandardError());
        if (m_output.size() > 16000) m_output = m_output.right(16000);
        emit installerOutputChanged();
    }
    void installerFinished(int exitCode, QProcess::ExitStatus exitStatus)
    {
        appendInstallerOutput();
        setStatus(exitStatus == QProcess::NormalExit && exitCode == 0
                  ? QStringLiteral("Installation complete — reboot when ready")
                  : QStringLiteral("Installation failed — review the log below"));
        emit installerRunningChanged();
    }

public:
    SystemActions()
    {
        connect(&m_installer, &QProcess::readyReadStandardOutput, this, &SystemActions::appendInstallerOutput);
        connect(&m_installer, &QProcess::readyReadStandardError, this, &SystemActions::appendInstallerOutput);
        connect(&m_installer, &QProcess::started, this, [this] {
            setStatus(QStringLiteral("Installing LokiOS…"));
            emit installerRunningChanged();
        });
        connect(&m_installer, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
                this, &SystemActions::installerFinished);
        connect(&m_installer, &QProcess::errorOccurred, this, [this](QProcess::ProcessError) {
            setStatus(QStringLiteral("Could not start installer — check permissions and logs"));
            emit installerRunningChanged();
            appendInstallerOutput();
        });
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

    if (engine.rootObjects().isEmpty()) return -1;
    return app.exec();
}

#include "main.moc"
