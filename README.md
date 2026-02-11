# RSS News Reader

这是一个基于 Qt 6 (QML + C++) 开发的桌面 RSS 阅读器。

## 功能特点

- **订阅管理**: 支持添加、删除 RSS 订阅源。
- **新闻阅读**: 浏览 RSS 订阅源中的新闻列表和详情。
- **收藏功能**: 支持收藏感兴趣的新闻。
- **自动刷新**: 支持后台定时刷新订阅源。
- **本地存储**: 使用 SQLite 数据库存储订阅源和用户数据，无需配置外部数据库。
- **图片缓存**: 自动缓存新闻图片，提升加载速度。

## 技术栈

- **前端**: Qt Quick / QML (Qt 6)
- **后端**: C++
- **数据库**: SQLite
- **构建系统**: CMake

## 如何构建和运行

### 前置要求

- Qt 6.8 或更高版本
- C++ 编译器 (MSVC, GCC, or Clang)
- CMake

### 构建步骤

1. 克隆仓库:
   ```bash
   git clone https://github.com/yourusername/rssnews.git
   ```

2. 使用 Qt Creator 打开 `CMakeLists.txt`。

3. 配置项目并构建。

4. 运行程序。

### 默认登录账号

首次运行时，系统会自动创建默认管理员账号：

- **用户名**: `admin`
- **密码**: `123456`

## 许可证

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。
