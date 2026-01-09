# 使用示例

本文档提供 SmartMobileAutomation 框架的实际使用示例。

## 示例 1: 图书馆座位预约

### 场景描述
在图书馆座位预约系统中，需要在指定时间（如 8:00）自动预约座位。

### 配置文件 (config.yaml)

```yaml
server_url: "http://127.0.0.1:4723"
target_time: "08:00:00"

app:
  package_name: "com.library.seatbooking"
  activity_name: ".MainActivity"

device:
  platform_version: "16"
  device_name: "emulator-5554"

flow_steps:
  - name: "点击预约入口"
    type: "click"
    required: true
    selectors:
      - type: "id"
        value: "com.library.seatbooking:id/book_entry"
      - type: "text"
        value: "座位预约"
  
  - name: "选择日期"
    type: "click"
    required: true
    selectors:
      - type: "xpath"
        value: "//android.widget.TextView[@text='今天']"
  
  - name: "选择座位区域"
    type: "click"
    required: true
    selectors:
      - type: "id"
        value: "com.library.seatbooking:id/area_A"
  
  - name: "选择具体座位"
    type: "click"
    required: true
    selectors:
      - type: "xpath"
        value: "//android.widget.Button[@text='A01']"
  
  - name: "确认预约"
    type: "click"
    required: true
    selectors:
      - type: "id"
        value: "com.library.seatbooking:id/confirm_button"
```

### 运行命令

```bash
python smart_mobile_automation.py "08:00:00"
```

## 示例 2: 医院挂号

### 场景描述
在医院挂号 App 中，需要在放号时间（如 9:00）自动挂号。

### 配置文件 (config.yaml)

```yaml
server_url: "http://127.0.0.1:4723"
target_time: "09:00:00"

app:
  package_name: "com.hospital.appointment"
  activity_name: ".MainActivity"

device:
  platform_version: "16"
  device_name: "emulator-5554"

flow_steps:
  - name: "进入挂号页面"
    type: "click"
    required: true
    selectors:
      - type: "id"
        value: "com.hospital.appointment:id/appointment_entry"
  
  - name: "选择科室"
    type: "click"
    required: true
    selectors:
      - type: "text"
        value: "内科"
  
  - name: "选择医生"
    type: "click"
    required: true
    selectors:
      - type: "xpath"
        value: "//android.widget.TextView[@text='张医生']"
  
  - name: "选择时间段"
    type: "click"
    required: true
    selectors:
      - type: "id"
        value: "com.hospital.appointment:id/time_slot_09_00"
  
  - name: "确认挂号"
    type: "click"
    required: true
    selectors:
      - type: "id"
        value: "com.hospital.appointment:id/confirm_appointment"
```

### 运行命令

```bash
python smart_mobile_automation.py "09:00:00"
```

## 示例 3: 课程选课

### 场景描述
在选课系统中，需要在选课开放时间（如 10:00）自动选择课程。

### 配置文件 (config.yaml)

```yaml
server_url: "http://127.0.0.1:4723"
target_time: "10:00:00"

app:
  package_name: "com.university.course"
  activity_name: ".MainActivity"

device:
  platform_version: "16"
  device_name: "emulator-5554"

flow_steps:
  - name: "进入选课页面"
    type: "click"
    required: true
    selectors:
      - type: "id"
        value: "com.university.course:id/course_selection"
  
  - name: "搜索课程"
    type: "input"
    required: true
    text: "计算机科学导论"
    selectors:
      - type: "id"
        value: "com.university.course:id/search_input"
  
  - name: "点击搜索结果"
    type: "click"
    required: true
    selectors:
      - type: "xpath"
        value: "(//android.widget.TextView[@text='计算机科学导论'])[1]"
  
  - name: "选择课程"
    type: "click"
    required: true
    selectors:
      - type: "id"
        value: "com.university.course:id/select_button"
  
  - name: "确认选课"
    type: "click"
    required: true
    selectors:
      - type: "id"
        value: "com.university.course:id/confirm_selection"
```

## 获取元素定位器的方法

### 方法 1: 使用 uiautomatorviewer

1. 连接 Android 设备
2. 打开 uiautomatorviewer（位于 Android SDK 的 tools/bin 目录）
3. 点击 "Device Screenshot" 按钮
4. 在界面中点击目标元素，查看右侧的属性信息
5. 复制 `resource-id` 或使用 XPath

### 方法 2: 使用 Appium Inspector

1. 启动 Appium Server
2. 打开 Appium Inspector
3. 配置 Desired Capabilities（与 config.yaml 中的配置一致）
4. 连接设备并获取元素信息

### 方法 3: 使用 adb 命令

```bash
# 获取当前页面 UI 结构
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml

# 查看 XML 文件，找到目标元素的 resource-id 或文本
```

## 选择器优先级建议

1. **优先使用 resource-id (id)**：最稳定，不易变化
2. **其次使用 XPath**：灵活但可能因 UI 变化而失效
3. **最后使用文本匹配**：最不稳定，但某些情况下是唯一选择

## 调试技巧

1. **添加等待步骤**：在关键操作之间添加 `wait` 步骤，确保页面加载完成
2. **配置备用选择器**：为关键步骤配置多个选择器，提高成功率
3. **设置 required: false**：对于非关键步骤，设置 `required: false`，避免因小问题导致整个流程失败
4. **查看日志**：关注控制台输出的阶段切换和操作日志

## 注意事项

⚠️ **重要提醒**：
- 请遵守目标 App 的用户协议
- 不要用于任何违法违规用途
- 仅用于个人效率提升和学习研究
- 建议在测试环境中先验证配置的正确性

