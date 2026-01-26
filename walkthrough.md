# MPV 0.41.0 升级指南

本文档记录了将 libmpv-darwin-build 升级到 MPV 0.41.0 的过程和关键注意事项。

## 升级概述

从旧版本升级到 MPV 0.41.0 需要进行以下关键改动：

1. **启用 libplacebo** - MPV 0.41.0 必须依赖 libplacebo
2. **启用 Swift 支持** - macOS 版本需要 Swift 进行 Cocoa 集成
3. **更新 meson 构建选项** - 移除已废弃的选项，添加新选项
4. **修复 SDK 版本不匹配** - Nix 的旧 SDK 与 Xcode Swift 版本不兼容

## 关键改动

### 1. 添加 libplacebo 依赖

MPV 0.41.0 强制要求 libplacebo，需要在 `nix/packages/` 下添加 libplacebo 包。

### 2. 启用 Swift 支持

macOS 版本需要 Swift 来实现 Cocoa 集成功能（剪贴板、输入上下文、媒体键等）。

**注意事项**：
- Nix 使用的 SDK 版本 (11.3/Swift 5.4) 与 Xcode Swift 版本 (6.0+) 不匹配
- 需要创建 wrapper 脚本来绕过 SDK 版本问题

#### 创建的 wrapper 脚本：

**swiftc.nix** - 过滤 meson 传递的 `-sdk` 参数，强制使用 Xcode 的 SDK：
```nix
# 核心逻辑：过滤 -sdk 参数，使用 Xcode SDK
for arg in "$@"; do
  if [ "$arg" = "-sdk" ]; then
    skip_next=true
    continue
  fi
  ...
done
exec swiftc -sdk ${xcodeSdk} "${args[@]}"
```

**xcrun.nix** - 让 `xcrun -find swiftc` 返回我们的 wrapper 路径：
```nix
case "$*" in
  *"-find swiftc"*)
    echo "${xctoolchainSwiftc}/bin/swiftc"
    ;;
  ...
esac
```

### 3. 更新 Cross-File

修改 `cross-files/macos-*.ini`：

```ini
# 从 10.9 升级到 10.15（Swift 要求）
min_version = '-mmacosx-version-min=10.15'

# 添加 swift 二进制
swift = xctoolchain + '/swiftc'
```

### 4. 修复 MetalLayer 条件编译

MPV 0.41.0 的 `view.swift` 无条件引用了 `MetalLayer` 类型，但该类型只在 Vulkan 启用时编译。

**创建的补丁** `patches/mpv-fix-view-metal-layer.patch`：
```swift
#if HAVE_VULKAN
    override var isOpaque: Bool {
        if let metalLayer = layer as? MetalLayer {
            return !metalLayer.isOpaque
        }
        return true
    }
#else
    override var isOpaque: Bool { return true }
#endif
```

### 5. 更新 Meson 构建选项

在 `mk-pkg-mpv/default.nix` 中：

```nix
# 移除已废弃的选项
# -Dlibmpv=true (改为 -Dlibmpv=shared)
# -Dgl=enabled (已废弃)

# 添加新选项
-Dlibplacebo=enabled
-Dswift-build=enabled  # 在 MACOS_OPTIONS 中
```

## 构建命令

升级版本号：修改这个文件libmpv-darwin-build/nix/utils/default/version.nix 


```bash
# 构建 macOS
nix build '.#mk-out-archive-xcframeworks-macos-universal-video-default' -L

# 构建 iOS
nix build '.#mk-out-archive-xcframeworks-ios-universal-video-default' -L

nix build -v '.#mk-out-archive-xcframeworks-ios-universal-video-default' '.#mk-out-archive-xcframeworks-macos-universal-video-default'

```

构建产物：

result/libmpv-xcframeworks_v0.41.0-preload_ios-universal-video-default.tar.gz (~19 MB)
result-1/libmpv-xcframeworks_v0.41.0-preload_macos-universal-video-default.tar.gz (~16 MB)

## 常见问题

### Q: 构建时出现 "no such module 'SwiftShims'" 错误
这是 SDK 版本不匹配导致的。确保使用了正确的 `swiftc.nix` wrapper。

### Q: 构建时出现 "cannot find type 'MetalLayer'" 错误
需要应用 `mpv-fix-view-metal-layer.patch` 补丁。

### Q: 为什么需要手动生成 `fftools-ffi.c`？
`fftools-ffi` 库本身提供的符号（如 `FFToolsFFIExecuteFFmpeg`）在 `libmpv` 中没有被显式调用。为了防止链接器将其作为死代码剔除（Dead Code Stripping），我们生成了一个极简的桩文件（Stub），引用这些符号以强制链接。

```c
#include "fftools-ffi/dart_api.h"
// Force link symbols by referencing them
void* a = FFToolsFFIInitialize;
void* b = FFToolsFFIExecuteFFmpeg;
...
```

注意：我们在 Dart 代码 (`ffmpeg.dart`) 中直接绑定了原生的 `FFToolsFFIExecuteFFmpeg` 符号，而不是使用中间层改名。这确保了架构的清洁性和性能。


### Q: macOS 应用点击 Play 卡死
这通常是因为 Swift 被禁用，导致 Cocoa 函数使用了空的 stub 实现。确保启用了 Swift 支持。

## 文件变更清单

| 文件 | 变更内容 |
|------|----------|
| `cross-files/macos-arm64.ini` | 添加 swift，min_version 改为 10.15 |
| `cross-files/macos-amd64.ini` | 添加 swift，min_version 改为 10.15 |
| `nix/utils/xctoolchain/swiftc.nix` | 创建 swiftc wrapper |
| `nix/utils/xctoolchain/xcrun.nix` | 创建 xcrun wrapper |
| `patches/mpv-fix-view-metal-layer.patch` | MetalLayer 条件编译补丁 |
| `nix/packages/mk-pkg-mpv/default.nix` | 更新构建选项，添加 Swift 支持 |
| `nix/packages/mk-pkg-libplacebo/` | 新增 libplacebo 包 |
