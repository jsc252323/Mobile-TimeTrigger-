# SmartMobileAutomation

通用 Android App UI 自动化框架 - 智能阶段控制版

## 📖 项目目的

本项目旨在提供一个**通用的 Android App UI 自动化框架**，帮助用户实现：

1. **个人效率提升**：自动化重复性的 App 操作流程，节省时间和精力
2. **学习研究**：了解 Android UI 自动化技术，学习 Appium 和 Selenium 的使用
3. **通用性设计**：不绑定任何特定 App，支持任意 Android 应用的自动化需求

**适用场景：**
- 图书馆座位预约自动化
- 医院挂号自动化
- 课程选课自动化
- 其他需要定时操作的 App 自动化场景

## 🎯 核心功能

### 1. 智能阶段控制引擎（PhaseControlEngine）

核心创新功能，根据目标时间自动调整操作频率：

- **目标时间前30秒以上**：安全模式（1-1.5秒/次）
  - 避免过早频繁操作，节省资源
- **目标时间前30秒到5秒**：模拟刷新模式（2-3秒/次）
  - 模拟正常用户行为，保持连接活跃
- **目标时间前5秒到后3秒**：黄金窗口模式（0.1-0.3秒/次）
  - 关键时刻加速操作，提高成功率
- **目标时间后3秒未成功**：降级模式（1-1.5秒/次，最多5次）
  - 智能降级，避免无效尝试

**特点：**
- 自动阶段切换，无需手动干预
- 随机抖动机制（±0.05秒），模拟真实用户行为
- 智能停止条件，避免无限循环

### 2. 完全可配置的流程引擎

通过 YAML 配置文件定义所有自动化步骤：

- **支持多种操作类型**：点击、输入、等待、滑动、检查
- **灵活的选择器系统**：支持 ID、XPath、UiAutomator、文本匹配等
- **备用选择器机制**：提高元素定位成功率
- **步骤依赖控制**：可设置步骤是否必需

### 3. 通用框架设计

- **不绑定特定 App**：通过配置文件适配任意 Android App
- **模块化架构**：阶段控制引擎可独立使用
- **易于扩展**：支持自定义流程步骤和操作类型

### 4. 智能重试机制

- 自动重试失败的流程
- 根据阶段调整重试策略
- 智能停止条件，避免无效尝试

## ⚠️ 重要声明

**本工具用于个人效率提升，支持任意 Android App 的 UI 自动化。**

**请遵守目标 App 的用户协议，不得用于任何违法违规用途。**

## ✨ 特性

- 🎯 **智能阶段控制**：根据目标时间自动调整操作频率
  - 目标时间前30秒：2-3秒/次（模拟正常刷新）
  - 目标时间前5秒→目标时间后3秒：0.1-0.3秒/次（黄金窗口加速）
  - 目标时间后3秒未成功：降回1秒/次，5次后停止
- 🔧 **完全可配置**：通过 YAML 配置文件定义所有元素定位器
- 📱 **通用框架**：支持任意 Android App，不绑定特定应用
- 🎲 **随机抖动**：±0.05秒随机延迟，模拟真实用户行为
- 🔄 **智能重试**：自动重试机制，提高成功率

## 📋 前置要求

- Python 3.7+
- Appium Server
- Android SDK
- 已连接的 Android 设备（真机或模拟器）

## 🚀 快速开始

### 1. 安装依赖

```bash
pip install -r requirements.txt
```

### 2. 配置 Appium

确保 Appium Server 正在运行：
```bash
appium
```

### 3. 配置目标 App

1. 复制配置文件：
```bash
cp config.example.yaml config.yaml
```

2. 编辑 `config.yaml`，配置：
   - 目标 App 的包名和启动 Activity
   - 设备信息
   - 自动化流程步骤
   - **元素定位器（需要用户自行获取）**

### 4. 获取元素定位器

使用 Android 开发者工具获取目标 App 的元素定位器：

**方法一：使用 uiautomatorviewer**
```bash
# 在 Android SDK 的 tools/bin 目录下
uiautomatorviewer
```

**方法二：使用 Appium Inspector**
- 启动 Appium Server
- 打开 Appium Inspector
- 连接设备并获取元素信息

**方法三：使用 adb**
```bash
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml
```

### 5. 运行脚本

**方式一：使用启动脚本（推荐）**

Windows 用户可以直接双击运行：
```bash
启动脚本.bat
```

启动脚本会自动：
- 检查 Python 环境
- 检查配置文件
- 检查设备连接
- 检查 Appium 服务器
- 启动自动化框架

**方式二：命令行运行**

```bash
python smart_mobile_automation.py [目标时间] [配置文件路径]
```

示例：
```bash
# 使用配置文件中的目标时间
python smart_mobile_automation.py

# 指定目标时间
python smart_mobile_automation.py "2025-01-20 20:00:00"

# 指定配置文件和目标时间
python smart_mobile_automation.py "20:00:00" config.yaml
```

## 📝 配置文件说明

配置文件采用 YAML 格式，主要包含以下部分：

### App 配置
```yaml
app:
  package_name: "com.example.app"  # 目标 App 包名
  activity_name: ".MainActivity"    # 启动 Activity
```

### 流程步骤配置
```yaml
flow_steps:
  - name: "步骤名称"
    type: "click"  # click, input, wait, swipe, check
    required: true
    selectors:
      - type: "id"
        value: "com.example.app:id/button"
```

### 选择器类型

- `id`: 使用 resource-id（推荐，最稳定）
- `xpath`: 使用 XPath 表达式
- `uiautomator`: 使用 UiAutomator 选择器
- `class_name`: 使用类名
- `text`: 精确文本匹配
- `text_contains`: 文本包含匹配

## 🎯 使用场景示例

### 场景 1: 图书馆座位预约

```yaml
app:
  package_name: "com.library.seat"
  activity_name: ".MainActivity"

flow_steps:
  - name: "点击预约按钮"
    type: "click"
    selectors:
      - type: "id"
        value: "com.library.seat:id/book_button"
  - name: "选择座位"
    type: "click"
    selectors:
      - type: "xpath"
        value: "//android.widget.Button[@text='座位A01']"
```

### 场景 2: 医院挂号

```yaml
app:
  package_name: "com.hospital.appointment"
  activity_name: ".MainActivity"

flow_steps:
  - name: "选择科室"
    type: "click"
    selectors:
      - type: "id"
        value: "com.hospital.appointment:id/department_list"
  - name: "选择医生"
    type: "click"
    selectors:
      - type: "text"
        value: "张医生"
```

## 🔧 阶段控制说明

框架会根据目标时间自动调整操作频率：

1. **目标时间前30秒以上**：安全模式，1-1.5秒/次
2. **目标时间前30秒到5秒**：模拟刷新，2-3秒/次
3. **目标时间前5秒到后3秒**：黄金窗口，0.1-0.3秒/次（加速）
4. **目标时间后3秒未成功**：降级模式，1-1.5秒/次，最多5次

## ⚠️ 注意事项

1. **元素定位器配置**：用户需要自行使用 Android 开发者工具获取目标 App 的元素定位器
2. **用户协议**：请遵守目标 App 的用户协议，不得用于违法违规用途
3. **设备连接**：确保设备已正确连接并通过 `adb devices` 验证
4. **Appium Server**：确保 Appium Server 正在运行
5. **App 登录**：确保目标 App 已登录（如需要）

## 🐛 常见问题

### Q: 如何获取元素定位器？
A: 使用 uiautomatorviewer 或 Appium Inspector 工具，详见"获取元素定位器"部分。

### Q: 选择器找不到元素？
A: 
1. 检查元素定位器是否正确
2. 尝试使用备用选择器
3. 检查 App 版本是否更新（元素可能已变化）
4. 增加等待时间

### Q: 脚本运行失败？
A:
1. 检查 Appium Server 是否运行
2. 检查设备是否连接
3. 检查配置文件格式是否正确
4. 检查目标 App 是否已安装并可以正常启动

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源许可证。

**重要声明：**
- 本软件仅供教育和个人效率提升使用
- 用户需确保使用本软件符合所有适用的法律法规
- 用户需遵守目标 App 的服务条款和用户协议
- 作者和贡献者不对任何误用或非法使用承担责任

**请负责任地使用本软件，遵守所有适用的法律和协议。**

## 🤝 贡献

欢迎提交 Issue 和 Pull Request，但请注意：
- 不要包含任何特定 App 的硬编码
- 保持框架的通用性
- 遵守开源社区规范

## 📞 支持

如有问题，请提交 Issue 或查看文档。

## 📚 相关文档

- [使用指南](使用指南/README.md) - 完整的安装和使用指南
- [安装指南](使用指南/安装指南.md) - 详细的依赖安装步骤
- [连接步骤](使用指南/连接步骤.md) - 设备连接详细教程
- [使用示例](USAGE_EXAMPLES.md) - 实际使用场景示例

---

**再次提醒：请遵守目标 App 的用户协议，本工具仅用于个人效率提升。**

