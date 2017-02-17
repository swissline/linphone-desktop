import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2

import Common 1.0
import Common.Styles 1.0
import Linphone 1.0
import Utils 1.0

import App.Styles 1.0

// =============================================================================

Window {
  id: incall

  // ---------------------------------------------------------------------------

  property var call
  property bool hideButtons: false

  // ---------------------------------------------------------------------------

  function _exit (cb) {
    incall.close()

    if (cb) {
      cb()
    }
  }

  // ---------------------------------------------------------------------------

  height: Screen.height
  width: Screen.width

  visible: true
  visibility: Window.FullScreen

  onActiveChanged: incall.showFullScreen()

  // ---------------------------------------------------------------------------

  Shortcut {
    sequence: StandardKey.Close
    onActivated: window.hide()
  }

  // ---------------------------------------------------------------------------

  Rectangle {
    anchors.fill: parent
    color: '#000000' // Not a style.
    focus: true

    Keys.onEscapePressed: incall.close()

    Camera {
      id: camera

      anchors.fill: parent
      call: incall.call
    }

    // -------------------------------------------------------------------------
    // Handle mouse move / Hide buttons.
    // -------------------------------------------------------------------------

    MouseArea {
      Timer {
        id: hideButtonsTimer

        interval: 5000
        running: true

        onTriggered: hideButtons = true
      }

      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      hoverEnabled: true
      propagateComposedEvents: true

      onEntered: hideButtonsTimer.start()
      onExited: hideButtonsTimer.stop()

      onPositionChanged: {
        hideButtonsTimer.stop()
        hideButtons = false
        hideButtonsTimer.start()
      }
    }

    ColumnLayout {
      anchors {
        fill: parent
        topMargin: CallStyle.header.topMargin
      }

      spacing: 0

      // -----------------------------------------------------------------------
      // Call info.
      // -----------------------------------------------------------------------

      Item {
        id: info

        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.leftMargin: CallStyle.header.leftMargin
        Layout.rightMargin: CallStyle.header.rightMargin
        Layout.preferredHeight: CallStyle.header.contactDescription.height

        Icon {
          id: callQuality

          anchors.left: parent.left
          icon: 'call_quality_0'
          iconSize: CallStyle.header.iconSize
          visible: !hideButtons

          // See: http://www.linphone.org/docs/liblinphone/group__call__misc.html#ga62c7d3d08531b0cc634b797e273a0a73
          Timer {
            interval: 5000
            repeat: true
            running: true
            triggeredOnStart: true

            onTriggered: {
              var quality = call.quality
              callQuality.icon = 'call_quality_' + (
                // Note: `quality` is in the [0, 5] interval.
                // It's necessary to map in the `call_quality_` interval. ([0, 3])
                quality >= 0 ? Math.round(quality / (5 / 3)) : 0
              )
            }
          }
        }

        // ---------------------------------------------------------------------
        // Timer.
        // ---------------------------------------------------------------------

        Text {
          id: elapsedTime

          anchors.fill: parent

          font.pointSize: CallStyle.header.elapsedTime.fullscreenFontSize

          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter

          // Not a customizable style.
          color: 'white'
          style: Text.Raised
          styleColor: 'black'

          Component.onCompleted: {
            var updateDuration = function () {
              text = Utils.formatElapsedTime(call.duration)
              Utils.setTimeout(elapsedTime, 1000, updateDuration)
            }

            updateDuration()
          }
        }

        // ---------------------------------------------------------------------
        // Video actions.
        // ---------------------------------------------------------------------

        ActionBar {
          anchors.right: parent.right
          iconSize: CallStyle.header.iconSize
          visible: !hideButtons

          ActionButton {
            icon: 'screenshot'

            onClicked: call.takeSnapshot()
          }

          ActionSwitch {
            enabled: call.recording
            icon: 'record'
            useStates: false

            onClicked: !enabled ? call.startRecording() : call.stopRecording()
          }

          ActionButton {
            icon: 'fullscreen'

            onClicked: _exit()
          }
        }
      }

      // -----------------------------------------------------------------------
      // Action Buttons.
      // -----------------------------------------------------------------------

      Item {
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true
        Layout.preferredHeight: CallStyle.actionArea.height
        visible: !hideButtons

        GridLayout {
          anchors {
            left: parent.left
            leftMargin: CallStyle.actionArea.leftButtonsGroupMargin
            verticalCenter: parent.verticalCenter
          }

          rowSpacing: ActionBarStyle.spacing

          ActionSwitch {
            enabled: !call.microMuted
            icon: 'micro'
            iconSize: CallStyle.actionArea.iconSize

            onClicked: call.microMuted = enabled
          }

          ActionSwitch {
            enabled: true
            icon: 'camera'
            iconSize: CallStyle.actionArea.iconSize
            updating: call.updating

            onClicked: _exit(function () { call.videoEnabled = false })
          }

          ActionButton {
            Layout.preferredHeight: CallStyle.actionArea.iconSize
            Layout.preferredWidth: CallStyle.actionArea.iconSize
            icon: 'options' // TODO: display options.
            iconSize: CallStyle.actionArea.iconSize
          }
        }

        ActionBar {
          anchors {
            right: parent.right
            rightMargin: CallStyle.actionArea.rightButtonsGroupMargin
            verticalCenter: parent.verticalCenter
          }
          iconSize: CallStyle.actionArea.iconSize

          ActionSwitch {
            enabled: !call.pausedByUser
            icon: 'pause'
            updating: call.updating

            onClicked: _exit(function () { call.pausedByUser = enabled })
          }

          ActionButton {
            icon: 'hangup'

            onClicked: _exit(call.terminate)
          }
        }
      }
    }
  }
}
