
import QtQuick
import QtQuick.Controls
import "content"

ApplicationWindow {
    id: root
    width: 1400
    height: 900
    visible: true
    title: qsTr("RSS News Reader")
    
    color: "#0f172a"

    Loader {
        id: mainLoader
        anchors.fill: parent
        focus: true
        
        Connections {
            target: mainLoader.item
            function onLogout() {
                console.log("Logging out...")
                mainLoader.source = ""
                loginDialog.open()
            }
        }
    }

    Component.onCompleted: {
        loginDialog.open()
    }

    PasswordDialog {
        id: loginDialog
        anchors.centerIn: parent
        
        onLoginSuccess: function() {
            console.log("Login successful, loading main interface...")
            mainLoader.source = "Main.qml"
        }
    }
}
