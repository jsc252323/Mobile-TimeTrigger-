# -*- coding: UTF-8 -*-
"""
__Author__ = "SmartMobileAutomation"
__Version__ = "1.0.0"
__Description__ = "通用 Android App UI 自动化框架 - 智能阶段控制版"
__Created__ = 2025/01/XX
__License__ = "MIT License - See LICENSE file for details"
__Features__ = 
    - 智能阶段控制（目标时间前/中/后）
    - 目标时间前30秒：2-3秒/次（模拟刷新）
    - 目标时间前5秒→目标时间后3秒：0.1-0.3秒/次（黄金窗口加速）
    - 目标时间后3秒未成功：降回1秒/次，5次后停止
    - 随机抖动机制（±0.05秒）
    - 完全可配置的元素定位器

Copyright (c) 2025 SmartMobileAutomation Contributors

This software is provided for educational and personal efficiency purposes only.
Users must ensure compliance with all applicable laws and target app user agreements.
"""

import time
import random
import sys
import os
import yaml
from datetime import datetime, timedelta

from appium import webdriver
from appium.options.common.base import AppiumOptions
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException


class PhaseControlEngine:
    """阶段控制引擎 - 核心通用逻辑"""
    
    # 阶段定义
    PHASE_PRE_30S = "pre_30s"      # 目标时间前30秒
    PHASE_GOLDEN = "golden"        # 黄金窗口（目标时间前5秒→目标时间后3秒）
    PHASE_POST_3S = "post_3s"      # 目标时间后3秒未成功
    PHASE_SAFE = "safe"             # 安全模式（降级后）
    
    def __init__(self, target_time):
        """
        初始化阶段控制引擎
        target_time: 目标时间 datetime 对象
        """
        self.target_time = target_time
        self.current_phase = self.PHASE_PRE_30S
        self.post_3s_attempts = 0
        self.max_post_3s_attempts = 5
        
        # 阶段频率配置
        self.phase_config = {
            self.PHASE_PRE_30S: {
                "min_delay": 2.0,
                "max_delay": 3.0,
                "random_range": 0.2,
                "description": "目标时间前30秒 - 模拟刷新"
            },
            self.PHASE_GOLDEN: {
                "min_delay": 0.1,
                "max_delay": 0.3,
                "random_range": 0.05,
                "description": "黄金窗口 - 适度加速"
            },
            self.PHASE_POST_3S: {
                "min_delay": 1.0,
                "max_delay": 1.5,
                "random_range": 0.3,
                "description": "目标时间后3秒未成功 - 降级模式"
            },
            self.PHASE_SAFE: {
                "min_delay": 1.0,
                "max_delay": 1.5,
                "random_range": 0.3,
                "description": "安全模式 - 持续降级"
            }
        }
    
    def get_current_phase(self):
        """根据当前时间判断所处阶段"""
        now = datetime.now()
        time_to_target = (self.target_time - now).total_seconds()
        time_after_target = (now - self.target_time).total_seconds()
        
        if time_to_target > 30:
            return self.PHASE_SAFE
        elif time_to_target > 5:
            return self.PHASE_PRE_30S
        elif time_to_target > -3:
            return self.PHASE_GOLDEN
        elif time_after_target <= 3:
            return self.PHASE_POST_3S
        else:
            if self.post_3s_attempts < self.max_post_3s_attempts:
                return self.PHASE_POST_3S
            else:
                return self.PHASE_SAFE
    
    def random_delay_with_phase(self):
        """根据当前阶段添加随机延迟"""
        phase = self.get_current_phase()
        
        if phase != self.current_phase:
            old_phase = self.current_phase
            self.current_phase = phase
            config = self.phase_config[phase]
            print(f"\n[阶段切换] {old_phase} → {phase}")
            print(f"  {config['description']}")
            print(f"  延迟范围: {config['min_delay']}-{config['max_delay']}秒")
        
        config = self.phase_config[phase]
        base_delay = random.uniform(config['min_delay'], config['max_delay'])
        random_offset = random.uniform(-config['random_range'], config['random_range'])
        delay = max(0.05, base_delay + random_offset)
        
        now = datetime.now()
        time_to_target = (self.target_time - now).total_seconds()
        if time_to_target > 0:
            print(f"[{phase}] 距离目标时间 {time_to_target:.1f}秒 | 等待 {delay:.3f}秒")
        else:
            print(f"[{phase}] 目标时间后 {abs(time_to_target):.1f}秒 | 等待 {delay:.3f}秒")
        
        time.sleep(delay)
        return delay


class SmartMobileAutomation:
    """通用 Android App UI 自动化框架"""
    
    def __init__(self, config_path="config.yaml", target_time_str=None):
        """
        初始化自动化框架
        config_path: 配置文件路径
        target_time_str: 目标时间字符串，格式 "2025-01-20 20:00:00" 或 "20:00:00"
        """
        self.config = self._load_config(config_path)
        self.driver = None
        self.wait = None
        
        # 解析目标时间
        self.target_time = self._parse_target_time(target_time_str)
        
        # 初始化阶段控制引擎
        self.phase_engine = PhaseControlEngine(self.target_time)
        
        self._setup_driver()
    
    def _load_config(self, config_path):
        """加载配置文件（支持 YAML）"""
        if not os.path.exists(config_path):
            raise FileNotFoundError(
                f"配置文件不存在: {config_path}\n"
                f"请复制 config.example.yaml 为 config.yaml 并配置"
            )
        
        with open(config_path, 'r', encoding='utf-8') as f:
            if config_path.endswith('.yaml') or config_path.endswith('.yml'):
                return yaml.safe_load(f)
            else:
                import json
                return json.load(f)
    
    def _parse_target_time(self, target_time_str):
        """解析目标时间"""
        if not target_time_str:
            if 'target_time' in self.config:
                target_time_str = self.config['target_time']
            else:
                print("未指定目标时间，将使用当前时间+30秒作为测试")
                return datetime.now() + timedelta(seconds=30)
        
        try:
            if len(target_time_str) > 10:
                return datetime.strptime(target_time_str, "%Y-%m-%d %H:%M:%S")
            else:
                today = datetime.now().date()
                time_part = datetime.strptime(target_time_str, "%H:%M:%S").time()
                return datetime.combine(today, time_part)
        except:
            print(f"时间格式错误，使用当前时间+30秒: {target_time_str}")
            return datetime.now() + timedelta(seconds=30)
    
    def _setup_driver(self):
        """初始化 Appium 驱动"""
        app_config = self.config.get('app', {})
        device_config = self.config.get('device', {})
        
        capabilities = {
            "platformName": "Android",
            "platformVersion": device_config.get('platform_version', '16'),
            "deviceName": device_config.get('device_name', 'emulator-5554'),
            "appPackage": app_config.get('package_name'),
            "appActivity": app_config.get('activity_name'),
            "unicodeKeyboard": True,
            "resetKeyboard": True,
            "noReset": True,
            "newCommandTimeout": 6000,
            "automationName": "UiAutomator2",
            "skipServerInstallation": False,
            "ignoreHiddenApiPolicyError": True,
            "disableWindowAnimation": True,
            "mjpegServerFramerate": 1,
            "shouldTerminateApp": False,
            "adbExecTimeout": 20000,
        }
        
        device_app_info = AppiumOptions()
        device_app_info.load_capabilities(capabilities)
        server_url = self.config.get('server_url', 'http://127.0.0.1:4723')
        self.driver = webdriver.Remote(server_url, options=device_app_info)
        
        time.sleep(5)
        self.driver.implicitly_wait(5)
        
        # 根据阶段调整性能设置
        phase = self.phase_engine.get_current_phase()
        if phase == self.phase_engine.PHASE_GOLDEN:
            self.driver.update_settings({
                "waitForIdleTimeout": 0,
                "actionAcknowledgmentTimeout": 0,
                "keyInjectionDelay": 0,
                "waitForSelectorTimeout": 500,
            })
            self.wait = WebDriverWait(self.driver, 1.5)
        else:
            self.driver.update_settings({
                "waitForIdleTimeout": 500,
                "actionAcknowledgmentTimeout": 500,
                "keyInjectionDelay": 100,
                "waitForSelectorTimeout": 2000,
            })
            self.wait = WebDriverWait(self.driver, 3)
    
    def _parse_selector(self, selector_config):
        """解析选择器配置"""
        selector_type = selector_config.get('type', 'id').lower()
        selector_value = selector_config.get('value')
        
        if selector_type == 'id':
            return (By.ID, selector_value)
        elif selector_type == 'xpath':
            return (By.XPATH, selector_value)
        elif selector_type == 'uiautomator':
            return (AppiumBy.ANDROID_UIAUTOMATOR, selector_value)
        elif selector_type == 'class_name':
            return (By.CLASS_NAME, selector_value)
        elif selector_type == 'text':
            return (AppiumBy.ANDROID_UIAUTOMATOR, f'new UiSelector().text("{selector_value}")')
        elif selector_type == 'text_contains':
            return (AppiumBy.ANDROID_UIAUTOMATOR, f'new UiSelector().textContains("{selector_value}")')
        else:
            raise ValueError(f"不支持的选择器类型: {selector_type}")
    
    def smart_click(self, selector_config, timeout=2.0):
        """智能点击 - 根据阶段调整速度"""
        try:
            phase = self.phase_engine.get_current_phase()
            actual_timeout = 1.0 if phase == self.phase_engine.PHASE_GOLDEN else timeout
            
            by, value = self._parse_selector(selector_config)
            el = WebDriverWait(self.driver, actual_timeout).until(
                EC.presence_of_element_located((by, value))
            )
            
            self.phase_engine.random_delay_with_phase()
            
            rect = el.rect
            x = rect['x'] + rect['width'] // 2
            y = rect['y'] + rect['height'] // 2
            
            duration = 50 if phase == self.phase_engine.PHASE_GOLDEN else 200
            self.driver.execute_script("mobile: clickGesture", {
                "x": x,
                "y": y,
                "duration": duration
            })
            return True
        except TimeoutException:
            return False
    
    def smart_wait_and_click(self, selector_config, backup_selectors=None, timeout=2.0):
        """智能等待和点击（支持备用选择器）"""
        selectors = [selector_config]
        if backup_selectors:
            selectors.extend(backup_selectors)
        
        phase = self.phase_engine.get_current_phase()
        actual_timeout = 1.0 if phase == self.phase_engine.PHASE_GOLDEN else timeout
        
        for selector in selectors:
            try:
                by, value = self._parse_selector(selector)
                el = WebDriverWait(self.driver, actual_timeout).until(
                    EC.presence_of_element_located((by, value))
                )
                self.phase_engine.random_delay_with_phase()
                
                rect = el.rect
                x = rect['x'] + rect['width'] // 2
                y = rect['y'] + rect['height'] // 2
                duration = 50 if phase == self.phase_engine.PHASE_GOLDEN else 200
                self.driver.execute_script("mobile: clickGesture", {
                    "x": x,
                    "y": y,
                    "duration": duration
                })
                return True
            except TimeoutException:
                continue
        return False
    
    def execute_automation_flow(self):
        """执行自动化流程（由用户根据具体 App 实现）"""
        # 这是一个模板方法，用户需要在子类中实现
        # 或通过配置文件定义流程步骤
        flow_steps = self.config.get('flow_steps', [])
        
        print("\n" + "=" * 60)
        print("开始自动化流程（智能阶段控制）...")
        print("=" * 60)
        
        phase = self.phase_engine.get_current_phase()
        config = self.phase_engine.phase_config[phase]
        print(f"当前阶段: {config['description']}")
        
        start_time = time.time()
        
        # 执行配置的流程步骤
        for i, step in enumerate(flow_steps, 1):
            step_name = step.get('name', f'步骤 {i}')
            step_type = step.get('type')
            selectors = step.get('selectors', [])
            
            print(f"\n[{i}/{len(flow_steps)}] {step_name}...")
            
            if step_type == 'click':
                # 单个点击
                if selectors:
                    success = self.smart_wait_and_click(
                        selectors[0],
                        selectors[1:] if len(selectors) > 1 else None
                    )
                    if not success:
                        print(f"⚠️  {step_name} 失败")
                        if step.get('required', True):
                            return False
            elif step_type == 'input':
                # 输入文本
                text = step.get('text', '')
                if selectors:
                    try:
                        by, value = self._parse_selector(selectors[0])
                        el = WebDriverWait(self.driver, 3).until(
                            EC.presence_of_element_located((by, value))
                        )
                        el.clear()
                        el.send_keys(text)
                        self.phase_engine.random_delay_with_phase()
                    except:
                        print(f"⚠️  {step_name} 失败")
                        if step.get('required', True):
                            return False
            elif step_type == 'wait':
                # 等待
                wait_time = step.get('time', 1.0)
                time.sleep(wait_time)
            elif step_type == 'swipe':
                # 滑动
                direction = step.get('direction', 'down')
                if direction == 'down':
                    self.driver.swipe(500, 400, 500, 2000, 300)
                self.phase_engine.random_delay_with_phase()
            elif step_type == 'check':
                # 检查元素是否存在
                if selectors:
                    by, value = self._parse_selector(selectors[0])
                    exists = len(self.driver.find_elements(by, value)) > 0
                    if not exists and step.get('required', True):
                        print(f"⚠️  {step_name} 检查失败")
                        return False
        
        end_time = time.time()
        elapsed = end_time - start_time
        print("\n" + "=" * 60)
        print(f"自动化流程完成，耗时: {elapsed:.2f}秒")
        print("=" * 60)
        
        return True
    
    def run_with_smart_retry(self, max_attempts=50):
        """智能重试机制"""
        print("=" * 60)
        print("智能阶段控制自动化模式")
        print("=" * 60)
        print(f"目标时间: {self.target_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"当前时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        now = datetime.now()
        time_to_target = (self.target_time - now).total_seconds()
        if time_to_target > 0:
            print(f"距离目标时间: {time_to_target:.1f}秒")
        else:
            print(f"目标时间后: {abs(time_to_target):.1f}秒")
        
        print("\n阶段说明:")
        print("  - 目标时间前30秒: 2-3秒/次（模拟刷新）")
        print("  - 目标时间前5秒→目标时间后3秒: 0.1-0.3秒/次（黄金窗口）")
        print("  - 目标时间后3秒未成功: 1秒/次，5次后停止")
        print("\n提示: 按 Ctrl+C 可随时停止脚本")
        print("=" * 60)
        
        try:
            for attempt in range(max_attempts):
                phase = self.phase_engine.get_current_phase()
                now = datetime.now()
                time_after_target = (now - self.target_time).total_seconds()
                
                if time_after_target > 30:
                    print(f"\n目标时间后已超过30秒（{time_after_target:.1f}秒），自动停止")
                    break
                
                if phase == self.phase_engine.PHASE_SAFE and self.phase_engine.post_3s_attempts >= self.phase_engine.max_post_3s_attempts:
                    print(f"\n已达到最大尝试次数（{self.phase_engine.max_post_3s_attempts}次），停止运行")
                    break
                
                if time_after_target > 10 and attempt >= 20:
                    print(f"\n目标时间后已超过10秒且尝试{attempt}次，停止运行")
                    break
                
                print(f"\n{'='*60}")
                print(f"第 {attempt + 1}/{max_attempts} 次尝试")
                print(f"{'='*60}")
                
                if self.execute_automation_flow():
                    print("\n✅ 自动化流程成功！")
                    return True
                
                if attempt < max_attempts - 1:
                    self.phase_engine.random_delay_with_phase()
                    try:
                        self.driver.quit()
                    except:
                        pass
                    self._setup_driver()
            
            print("\n" + "=" * 60)
            print("所有尝试均失败或已达到停止条件")
            print("=" * 60)
            return False
            
        except KeyboardInterrupt:
            print("\n\n" + "=" * 60)
            print("用户中断（Ctrl+C）")
            print("正在清理资源...")
            print("=" * 60)
            try:
                if self.driver:
                    self.driver.quit()
            except:
                pass
            print("脚本已停止")
            return False
        except Exception as e:
            print(f"\n发生错误: {e}")
            try:
                if self.driver:
                    self.driver.quit()
            except:
                pass
            return False


# 使用示例
if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("SmartMobileAutomation - 通用 Android App UI 自动化框架")
    print("=" * 60)
    print("\n特性:")
    print("  ✅ 智能阶段控制")
    print("  ✅ 完全可配置的元素定位器")
    print("  ✅ 支持任意 Android App")
    print("\n" + "=" * 60 + "\n")
    
    import sys
    target_time_str = None
    config_path = "config.yaml"
    
    if len(sys.argv) > 1:
        target_time_str = sys.argv[1]
    if len(sys.argv) > 2:
        config_path = sys.argv[2]
    
    bot = SmartMobileAutomation(config_path=config_path, target_time_str=target_time_str)
    bot.run_with_smart_retry(max_attempts=50)

