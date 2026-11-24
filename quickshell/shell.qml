//@ pragma IconTheme breeze

import Quickshell
import Quickshell.I3
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Widgets


ShellRoot {
  PanelWindow {
    anchors {
      top: true; left: true; right: true
    }
    implicitHeight: 20
    color: "#323232"

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      spacing: 12

      Repeater {
        model: I3.workspaces
        delegate: Text {
          required property var modelData
          text: modelData.name
          color: modelData.focused ? "#ffffff" : "#888888"
          font.pixelSize: 11

          MouseArea {
            anchors.fill: parent
            onClicked: I3.dispatch("workspace " + modelData.name)
          }
        }
      }

      Item {
        Layout.fillWidth: true
      }

      // Bandeja del sistema (iconos StatusNotifier)
      Row {
        id: tray
        spacing: 6

        Repeater {
          model: SystemTray.items
          delegate: Item {
            id: trayItem
            required property var modelData
            implicitWidth: 16
            implicitHeight: 16

            Rectangle {
              anchors.fill: parent
              radius: 3
              color: trayArea.containsMouse ? "#3d3d3d" : "transparent"
            }

            IconImage {
              anchors.fill: parent
              source: trayItem.modelData.icon
              mipmap: true
            }

            // Reserva: si la app no da icono, muestra la inicial del título
            Text {
              anchors.centerIn: parent
              visible: trayItem.modelData.icon === ""
              text: trayItem.modelData.title ? trayItem.modelData.title.charAt(0).toUpperCase() : "?"
              color: "#dddddd"
              font.pixelSize: 10
            }

            QsMenuAnchor {
              id: trayMenu
              menu: trayItem.modelData.menu
              anchor.item: trayItem
              anchor.edges: Edges.Bottom | Edges.Right
              anchor.gravity: Edges.Bottom | Edges.Left
              anchor.margins.top: 4
            }

            MouseArea {
              id: trayArea
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor

              onClicked: (mouse) => {
                if (trayMenu.visible) {
                  trayMenu.close()
                  return
                }
                if (mouse.button === Qt.MiddleButton) {
                  trayItem.modelData.secondaryActivate()
                } else if (mouse.button === Qt.LeftButton && !trayItem.modelData.onlyMenu) {
                  trayItem.modelData.activate()
                } else if (trayItem.modelData.hasMenu) {
                  trayMenu.open()
                } else if (mouse.button === Qt.RightButton) {
                  trayItem.modelData.secondaryActivate()
                }
              }

              onWheel: (wheel) => {
                if (wheel.angleDelta.y !== 0)
                  trayItem.modelData.scroll(wheel.angleDelta.y, false)
              }
            }
          }
        }
      }


      Text {
        readonly property var dev: UPower.displayDevice
        readonly property int pct: Math.round(dev.percentage * 100)
        text: {
          if (!dev.isPresent) return "Sin batería"
          var s = dev.state === UPowerDeviceState.Charging ? "AC " : "BAT "
          return s + pct + "%"
        }
        color: pct <= 25 && dev.state !== UPowerDeviceState.Charging ? "#ff5555" : "#ffffff"
        font.pixelSize: 11
      }
      Text {
        id: clock
        color: "#ffffff"
        font.pixelSize: 11

        Timer {
          interval: 1000
          running: true
          repeat: true
          triggeredOnStart: true
          onTriggered: clock.text = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss")
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: calendar.visible = !calendar.visible
        }
      }
    }

    // Calendario desplegable, anclado justo debajo del reloj
    PopupWindow {
      id: calendar

      anchor.item: clock
      anchor.edges: Edges.Bottom | Edges.Right
      anchor.gravity: Edges.Bottom | Edges.Left
      anchor.margins.top: 4

      visible: false
      implicitWidth: 270
      implicitHeight: 218
      color: "transparent"

      // Vuelve al mes actual cada vez que se abre
      onVisibleChanged: if (visible) shownDate = new Date()

      property date shownDate: new Date()
      readonly property int shownYear: shownDate.getFullYear()
      readonly property int shownMonth: shownDate.getMonth()

      readonly property var monthNames: [
        "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
      ]
      readonly property var weekDayNames: ["L", "M", "X", "J", "V", "S", "D"]

      // 42 celdas (6 semanas) empezando en lunes
      readonly property var cells: {
        var y = shownYear
        var m = shownMonth
        var offset = (new Date(y, m, 1).getDay() + 6) % 7
        var today = new Date()
        var out = []
        for (var i = 0; i < 42; i++) {
          var d = new Date(y, m, i - offset + 1)
          out.push({
            day: d.getDate(),
            inMonth: d.getMonth() === m,
            isToday: d.getFullYear() === today.getFullYear()
            && d.getMonth() === today.getMonth()
            && d.getDate() === today.getDate()
          })
        }
        return out
      }

      function shiftMonth(delta) {
        shownDate = new Date(shownYear, shownMonth + delta, 1)
      }

      Rectangle {
        id: calendarBg
        anchors.fill: parent
        color: "#2b2b2b"
        border.color: "#454545"
        border.width: 1
        radius: 8

        HoverHandler {
          onHoveredChanged: {
            if (hovered) closeTimer.stop()
            else closeTimer.start()
          }
        }

        Item {
          id: content
          anchors.fill: parent
          anchors.margins: 10

          // Cabecera: mes/año y flechas de navegación
          Item {
            id: header
            width: parent.width
            height: 20

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: calendar.monthNames[calendar.shownMonth] + " " + calendar.shownYear
              color: "#ffffff"
              font.pixelSize: 12
              font.bold: true
            }

            Item {
              id: prevButton
              width: 20; height: 20
              anchors.right: nextButton.left
              anchors.rightMargin: 4
              anchors.verticalCenter: parent.verticalCenter

              Text {
                anchors.centerIn: parent
                text: "‹"
                color: prevArea.containsMouse ? "#ffffff" : "#999999"
                font.pixelSize: 16
              }
              MouseArea {
                id: prevArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: calendar.shiftMonth(-1)
              }
            }

            Item {
              id: nextButton
              width: 20; height: 20
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter

              Text {
                anchors.centerIn: parent
                text: "›"
                color: nextArea.containsMouse ? "#ffffff" : "#999999"
                font.pixelSize: 16
              }
              MouseArea {
                id: nextArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: calendar.shiftMonth(1)
              }
            }
          }

          // Nombres de los días
          Row {
            id: weekHeader
            anchors.top: header.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2

            Repeater {
              model: calendar.weekDayNames
              delegate: Text {
                required property var modelData
                width: 34
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: "#888888"
                font.pixelSize: 10
              }
            }
          }

          // Días del mes
          Grid {
            id: daysGrid
            anchors.top: weekHeader.bottom
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
              model: calendar.cells
              delegate: Rectangle {
                required property var modelData
                width: 34
                height: 24
                radius: 4
                color: modelData.isToday
                ? "#3b82f6"
                : (dayHover.hovered && modelData.inMonth ? "#3d3d3d" : "transparent")

                HoverHandler {
                  id: dayHover
                }

                Text {
                  anchors.centerIn: parent
                  text: modelData.day
                  color: modelData.isToday ? "#ffffff"
                  : (modelData.inMonth ? "#dddddd" : "#5c5c5c")
                  font.pixelSize: 11
                  font.bold: modelData.isToday
                }
              }
            }
          }
        }
      }

      // Cierra el calendario al sacar el ratón (con un pequeño margen)
      Timer {
        id: closeTimer
        interval: 500
        onTriggered: calendar.visible = false
      }
    }
  }
}
