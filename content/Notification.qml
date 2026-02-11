import QtQuick
import QtQuick.Controls

Rectangle {
    id: notification

    property int duration: 5000 // 默认显示 5 秒

    z: 999 // 确保显示在最上层
    width: Math.min(parent.width * 0.8, 400)
    height: 40
    radius: 8
    color: "#323232"
    
    // 顶部居中显示
    anchors.top: parent.top
    anchors.topMargin: 20
    anchors.horizontalCenter: parent.horizontalCenter
    
    // 初始状态隐藏
    opacity: 0
    visible: opacity > 0

    // 淡入淡出动画
    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    Label {
        id: messageText
        anchors.centerIn: parent
        color: "#ffffff"
        font.pixelSize: 14
        elide: Text.ElideRight
        width: parent.width - 20
        horizontalAlignment: Text.AlignHCenter
    }

    // 自动关闭计时器
    Timer {
        id: autoCloseTimer
        interval: notification.duration
        onTriggered: notification.close()
    }

    // 显示通知的方法
    function show(message) {
        messageText.text = message
        opacity = 1
        autoCloseTimer.restart()
    }

    // 关闭通知的方法
    function close() {
        opacity = 0
        autoCloseTimer.stop()
    }
    
    // 点击通知可立即关闭
    MouseArea {
        anchors.fill: parent
        onClicked: notification.close()
    }
}
