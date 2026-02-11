// 导入QtQuick模块，提供基础QML类型
import QtQuick
// 导入QtQuick.Controls模块，提供UI控件
import QtQuick.Controls
// 导入QtQuick.Layouts模块，提供布局功能
import QtQuick.Layouts

// 定义一个对话框组件
Dialog {
    // 对话框的唯一标识符
    id: root

    // 对话框标题文本
    title: qsTr("登录")
    // 设置为模态对话框，阻塞其他窗口交互
    modal: true
    // 对话框宽度为父容器宽度
    width: parent.width
    // 对话框高度为父容器高度
    height: parent.height

    property bool isLogin: true

    // 定义属性：登录成功时的回调函数，传递账号和密码参数
    property var onLoginSuccess: null

    //通知组件
    Notification {
        id: notification
    }


    // 延迟关闭计时器
    Timer {
        id: closeTimer
        interval: 1000 // 延迟 1 秒关闭，让用户看到提示
        onTriggered: root.accept()
    }

    function attemptLogin() {
        // 检查用户名和密码是否为空
        var username = String(usernameInput.text)
        var password = String(passwordInput.text)
        if (username === "" || password === "") {
            // 显示错误提示
            errorMessage.text = qsTr("请输入账号和密码")
            errorMessage.visible = true
            // 清空密码输入框
            passwordInput.clear()
            // 强制密码输入框获得焦点
            passwordInput.focus = true
            // 退出
            return
        }
        if(!isLogin)
        {
            var registerResult = databaseManager.registerUser(username, password)
            if(registerResult == "注册成功")
            {
                // 调用
                 notification.show("注册成功，跳转主界面中...")
                 closeTimer.start()

            }
            else
            {
                // 注册失败，显示错误提示
                errorMessage.text = registerResult
                errorMessage.visible = true
                // 清空密码输入框
                passwordInput.clear()
                // 强制密码输入框获得焦点
                passwordInput.focus = true
                // 退出
                return
            }
        }
        else{
            // 调用数据库管理器的验证方法
            if (databaseManager.verifyUser(username, password)) {
                console.log("数据库验证成功")
                // 验证成功，关闭对话框
                notification.show("登录成功，跳转主界面中...")
                closeTimer.start()
            } else {
                // 验证失败，显示错误提示
                errorMessage.text = qsTr("账号或密码错误，请重试")
                errorMessage.visible = true
                passwordInput.clear()
                passwordInput.focus = true
            }
        }
    }

    // 对话框背景样式
    background: Rectangle {
        color: "#ffffff"
        radius: 10
        border.color: "#e0e0e0"
        border.width: 1
    }

    // 创建一个垂直布局容器
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 标题文本
        Text {
            id: loginTitle
            text: qsTr("欢迎登录")
            font.pixelSize: 24
            font.bold: true
            color: "#333333"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // 账号输入框容器
        Rectangle {
            width: parent.width
            height: 45
            radius: 8
            color: "#f5f5f5"
            border.color: usernameInput.focus ? "#4CAF50" : "#e0e0e0"
            border.width: 2

            // 账号图标
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "👤"
                font.pixelSize: 20
            }

            // 账号输入框
            TextField {
                id: usernameInput
                anchors.left: parent.left
                anchors.leftMargin: 40
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: qsTr("请输入账号")
                background: Rectangle {
                    color: "transparent"
                }
                onAccepted: {
                    passwordInput.focus = true
                }
            }
        }

        // 密码输入框容器
        Rectangle {
            width: parent.width
            height: 45
            radius: 8
            color: "#f5f5f5"
            border.color: passwordInput.focus ? "#4CAF50" : "#e0e0e0"
            border.width: 2

            // 密码图标
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "🔒"
                font.pixelSize: 20
            }

            // 密码输入框
            TextField {
                id: passwordInput
                anchors.left: parent.left
                anchors.leftMargin: 40
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                placeholderText: qsTr("请输入密码")
                background: Rectangle {
                    color: "transparent"
                }
                onAccepted: {
                    attemptLogin()
                }
            }
        }

        Text{
            id:loginMessage
            text:isLogin ? qsTr("注册") : qsTr("登录")
            font.pixelSize: 14
            color: "#333333"
            anchors.right: parent.right
            TapHandler {
                onTapped: {
                    isLogin = !isLogin
                    loginTitle.text = isLogin ? qsTr("欢迎登录") : qsTr("注册")
                    loginMessage.text = isLogin ? qsTr("注册") : qsTr("登录")
                }
            }
        }

     
        // 错误提示文本
        Text {
            id: errorMessage
            text: qsTr("账号或密码错误，请重试")
            color: "#ff5252"
            font.pixelSize: 14
            visible: false
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // 自定义按钮样式
    // 自定义按钮样式
    footer: Item {
        // 设置footer的高度为60像素
        height: 60

        // 创建一个水平行布局容器
        RowLayout {
            // 锚点填充父容器
            anchors.fill: parent
            // 设置边距为10像素
            anchors.margins: 10
            // 子元素之间的间距为10像素
            spacing: 10

            // 左侧取消按钮
            Button {
                // 按钮显示的文本
                text: qsTr("取消")
                // 按钮宽度为100像素
                width: 100
                // 按钮高度为40像素
                height: 40
                // 垂直居中对齐
                Layout.alignment: Qt.AlignVCenter

                // 按钮背景样式
                background: Rectangle {
                    // 按下时颜色为深灰色，否则为浅灰色
                    color: parent.pressed ? "#e0e0e0" : "#f5f5f5"
                    // 圆角半径为8像素
                    radius: 8
                    // 边框颜色为浅灰色
                    border.color: "#e0e0e0"
                    // 边框宽度为1像素
                    border.width: 1
                }

                // 按钮内容样式
                contentItem: Text {
                    // 显示按钮文本
                    text: parent.text
                    // 文本颜色为深灰色
                    color: "#666666"
                    // 字体大小为14像素
                    font.pixelSize: 14
                    // 水平居中对齐
                    horizontalAlignment: Text.AlignHCenter
                    // 垂直居中对齐
                    verticalAlignment: Text.AlignVCenter
                }

                // 点击事件处理
                onClicked: {
                    // 调用对话框的reject方法，触发onRejected信号
                    root.reject()
                }
            }

            // 弹簧，将登录按钮推到右边
            Item {
                // 填充可用宽度
                Layout.fillWidth: true
            }

            // 右侧登录按钮
            Button {
                // 按钮显示的文本
                text: isLogin ? qsTr("登录") : qsTr("注册")
                // 按钮宽度为100像素
                width: 100
                // 按钮高度为40像素
                height: 40
                // 垂直居中对齐
                Layout.alignment: Qt.AlignVCenter

                // 按钮背景样式
                background: Rectangle {
                    // 按下时颜色为深绿色，否则为绿色
                    color: parent.pressed ? "#43A047" : "#4CAF50"
                    // 圆角半径为8像素
                    radius: 8
                }

                // 按钮内容样式
                contentItem: Text {
                    // 显示按钮文本
                    text: parent.text
                    // 文本颜色为白色
                    color: "#ffffff"
                    // 字体大小为14像素
                    font.pixelSize: 14
                    // 字体加粗
                    font.bold: true
                    // 水平居中对齐
                    horizontalAlignment: Text.AlignHCenter
                    // 垂直居中对齐
                    verticalAlignment: Text.AlignVCenter
                }

                // 点击事件处理
                onClicked: attemptLogin()
            }
        }
    }

    // 当点击确定按钮时触发
    onAccepted: {
        // 关闭对话框
        root.close()
        // 如果定义了登录成功回调函数
        if (root.onLoginSuccess) {
            // 执行回调函数，传递账号和密码
            root.onLoginSuccess()
        } else {
            console.log("错误：没有定义回调函数")
        }
    }

    // 当点击取消按钮时触发
    onRejected: {
        // 退出应用程序
        Qt.quit()
    }

    // 当组件完成加载时触发
    Component.onCompleted: {
        // 强制账号输入框获得焦点
        usernameInput.forceActiveFocus()
    }
}
