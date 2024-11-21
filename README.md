# 端口映射器

一个简单易用的 macOS 状态栏应用，用于管理 SSH 端口转发。

## 概述
针对Mac OS的状态栏应用，实现了端口映射的管理和控制。可以快速的把目标主机端口映射到本地，方便开发。

## 功能特点

### 已实现功能
- ✅ 状态栏应用，简洁不占空间
- ✅ 支持密钥认证
- ✅ 配置自动保存
- ✅ 支持多端口映射
- ✅ 实时连接状态监控
- ✅ 配置列表显示
- ✅ 配置的增删改查
- ✅ 开机自动连接
- ✅ 连接测试功能
- ✅ 连接测试反馈

### 待完成功能
- ❌ ssh挂载 （sshfs）（重要）
- ❌ 基本日志查看功能
- ❌ 支持密码认证
- ❌ 自动重连机制，保持连接稳定
- ❌ 完整的错误处理
- ❌ 完整的日志记录
- ❌ 日志持久化
- ❌ 日志过滤和搜索
- ❌ 系统通知
- ❌ 快捷键支持

## 系统要求

- macOS 12.0 或更高版本
- 需要目标服务器支持 SSH 连接

## 使用方法

1. 从应用程序文件夹启动"端口映射器"
2. 点击状态栏图标打开主界面
3. 添加新的端口映射：
   - 服务器地址
   - SSH 端口（默认 22）
   - 用户名和认证信息
   - 本地端口和远程端口
4. 点击开关按钮启动或停止端口映射

## 开发相关

- 使用 SwiftUI 构建用户界面
- Swift 5.5+ 异步并发支持
- 原生 SSH 命令行工具
- 文件系统存储配置

## 注意事项

- 请确保本地端口未被其他应用占用
- 建议使用密钥认证以提高安全性
- 如遇连接问题，请查看日志了解详情

## 反馈建议

如有问题或建议，请通过以下方式反馈：
1. 提交 Issue
2. 发送邮件至开发者

## 鸣谢

Windsurf（https://github.com/windsurf/windsurf），代码均由伟大的Windsurf生成，感谢他的贡献！

## 许可证

MIT License
