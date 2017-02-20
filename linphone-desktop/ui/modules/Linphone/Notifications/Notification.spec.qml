import QtTest 1.1

import Linphone 1.0
import Utils 1.0

// =============================================================================

// Check defined properties/methods used in `Notifier.cpp`.
TestCase {
  Notification {
    id: notification
  }

  function test_notificationDataProperty () {
    compare(Utils.isObject(notification.notificationData), true)
  }

  function test_notificationHeightProperty () {
    compare(Utils.isInteger(notification.notificationHeight), true)
  }

  function test_notificationOffsetProperty () {
    compare(Utils.isInteger(notification.notificationOffset), true)
  }

  function test_notificationShowMethod () {
    compare(Utils.isFunction(notification.show), true)
  }

  function test_childWindow () {
    compare(Utils.qmlTypeof(notification.data[0], 'QQuickWindowQmlImpl'), true)
  }
}