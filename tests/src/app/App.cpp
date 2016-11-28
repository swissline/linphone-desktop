#include <QMenu>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickView>
#include <QtDebug>

#include "../components/chat/ChatProxyModel.hpp"
#include "../components/contacts/ContactModel.hpp"
#include "../components/contacts/ContactsListModel.hpp"
#include "../components/contacts/ContactsListProxyModel.hpp"
#include "../components/core/CoreManager.hpp"
#include "../components/notifier/Notifier.hpp"
#include "../components/settings/AccountSettingsModel.hpp"
#include "../components/timeline/TimelineModel.hpp"

#include "App.hpp"

#define LANGUAGES_PATH ":/languages/"
#define WINDOW_ICON_PATH ":/assets/images/linphone.png"

// The two main windows of Linphone desktop.
#define QML_VIEW_MAIN_WINDOW "qrc:/ui/views/App/MainWindow/MainWindow.qml"
#define QML_VIEW_CALL_WINDOW "qrc:/ui/views/App/Calls/Calls.qml"

// ===================================================================

App *App::m_instance = nullptr;

App::App (int &argc, char **argv) : QApplication(argc, argv) {
  QString current_locale = QLocale::system().name();

  // Try to use default locale. Otherwise use english.
  if (m_translator.load(QString(LANGUAGES_PATH) + current_locale)) {
    installTranslator(&m_translator);
    m_locale = current_locale;
  } else if (m_translator.load(LANGUAGES_PATH "en")) {
    installTranslator(&m_translator);
  } else {
    qFatal("No translation found.");
  }

  setWindowIcon(QIcon(WINDOW_ICON_PATH));

  // Provide `+custom` folders for custom components.
  m_file_selector = new QQmlFileSelector(&m_engine);
  m_file_selector->setExtraSelectors(QStringList("custom"));

  // Set modules paths.
  m_engine.addImportPath(":/ui/modules");
  m_engine.addImportPath(":/ui/scripts");
  m_engine.addImportPath(":/ui/views");
}

// -------------------------------------------------------------------

void App::initContentApp () {
  // Init core.
  CoreManager::init();

  // Register types and load context properties.
  registerTypes();
  addContextProperties();

  // Load main view.
  m_engine.load(QUrl(QML_VIEW_MAIN_WINDOW));
  if (m_engine.rootObjects().isEmpty())
    qFatal("Unable to open main window.");

  // Enable TrayIconSystem.
  if (!QSystemTrayIcon::isSystemTrayAvailable())
    qWarning("System tray not found on this system.");
  else
    setTrayIcon();
}

void App::registerTypes () {
  // Register meta types.
  qmlRegisterUncreatableType<Presence>(
    "Linphone", 1, 0, "Presence", "Presence is uncreatable"
  );
  qRegisterMetaType<ChatModel::EntryType>("ChatModel::EntryType");

  // Register Application/Core.
  qmlRegisterSingletonType<App>(
    "Linphone", 1, 0, "App",
    [](QQmlEngine *, QJSEngine *) -> QObject *{
      return App::getInstance();
    }
  );

  qmlRegisterSingletonType<CoreManager>(
    "Linphone", 1, 0, "CoreManager",
    [](QQmlEngine *, QJSEngine *) -> QObject *{
      return CoreManager::getInstance();
    }
  );

  // Register models.
  ContactsListProxyModel::initContactsListModel(new ContactsListModel());
  qmlRegisterType<ContactsListProxyModel>("Linphone", 1, 0, "ContactsListProxyModel");

  qmlRegisterType<ChatModel>("Linphone", 1, 0, "ChatModel");
  qmlRegisterType<ChatProxyModel>("Linphone", 1, 0, "ChatProxyModel");

  // Register singletons.
  qmlRegisterSingletonType<ContactsListModel>(
    "Linphone", 1, 0, "ContactsListModel",
    [](QQmlEngine *, QJSEngine *) -> QObject *{
      return ContactsListProxyModel::getContactsListModel();
    }
  );

  qmlRegisterSingletonType<AccountSettingsModel>(
    "Linphone", 1, 0, "AccountSettingsModel",
    [](QQmlEngine *, QJSEngine *) -> QObject *{
      return new AccountSettingsModel();
    }
  );

  qmlRegisterSingletonType<TimelineModel>(
    "Linphone", 1, 0, "TimelineModel",
    [](QQmlEngine *, QJSEngine *) -> QObject *{
      return new TimelineModel(ContactsListProxyModel::getContactsListModel());
    }
  );
}

void App::addContextProperties () {
  QQmlContext *context = m_engine.rootContext();
  QQmlComponent component(&m_engine, QUrl(QML_VIEW_CALL_WINDOW));

  // Windows.
  if (component.isError()) {
    qWarning() << component.errors();
  } else {
    //context->setContextProperty("CallsWindow", component.create());
  }

  m_notifier = new Notifier();
  context->setContextProperty("Notifier", m_notifier);
}

void App::setTrayIcon () {
  QQuickWindow *root = qobject_cast<QQuickWindow *>(m_engine.rootObjects().at(0));
  QMenu *menu = new QMenu();

  m_system_tray_icon = new QSystemTrayIcon(root);

  // trayIcon: Right click actions.
  QAction *quit_action = new QAction("Quit", root);
  root->connect(quit_action, &QAction::triggered, qApp, &QCoreApplication::quit);

  QAction *restore_action = new QAction("Restore", root);
  root->connect(restore_action, &QAction::triggered, root, &QQuickWindow::showNormal);

  // trayIcon: Left click actions.
  root->connect(m_system_tray_icon, &QSystemTrayIcon::activated, [root](QSystemTrayIcon::ActivationReason reason) {
    if (reason == QSystemTrayIcon::Trigger) {
      if (root->visibility() == QWindow::Hidden)
        root->showNormal();
      else
        root->hide();
    }
  });

  // Build trayIcon menu.
  menu->addAction(restore_action);
  menu->addSeparator();
  menu->addAction(quit_action);

  m_system_tray_icon->setContextMenu(menu);
  m_system_tray_icon->setIcon(QIcon(WINDOW_ICON_PATH));
  m_system_tray_icon->setToolTip("Linphone");
  m_system_tray_icon->show();
}