# SnapNotion Technical Requirements
## 技术需求规范文档

### Overview / 概述

This document defines the technical requirements, platform specifications, performance targets, and implementation constraints for SnapNotion across all supported Apple platforms.

本文档定义了 SnapNotion 在所有支持的苹果平台上的技术需求、平台规范、性能目标和实施约束。

---

## 🖥️ Platform Support / 平台支持

### Apple Ecosystem Coverage / 苹果生态覆盖

#### Primary Platforms (Phase 1)
- **iOS 16.0+**: iPhone 12 and later
- **iPadOS 16.0+**: iPad (9th generation) and later, iPad Pro (all models)
- **macOS 13.0+**: Intel Macs (2019+), Apple Silicon Macs (all models)
- **Mac Catalyst**: Optimized desktop experience on macOS

#### Future Platform Support (Phase 2-3)
- **watchOS**: Quick capture and task notifications
- **tvOS**: Knowledge graph visualization on large screens
- **visionOS**: Immersive knowledge exploration (when available)

### Device Specifications / 设备规格

#### iPhone Requirements
```
Minimum Supported:
- iPhone 12 (A14 Bionic)
- 4GB RAM
- 64GB storage (8GB free for app)
- iOS 16.0+

Recommended:
- iPhone 14 Pro or later
- 6GB+ RAM
- 128GB+ storage
- iOS 17.0+
```

## 🔧 Gesture Interaction Technical Implementation / 手势交互技术实现

### Gesture Conflict Resolution Strategy / 手势冲突解决方案

#### Gesture Processing Priority / 手势处理优先级
```javascript
// 手势处理优先级系统
1. SwipeableItem 手势优先 (stopPropagation + preventDefault)
   - 左滑: 显示 Edit (蓝色) + More (紫色) 按钮
   - 右滑: 显示收藏操作和红色心形反馈

2. Header 区域面板切换手势

3. 内容区域垂直滚动

4. 全局手势作为后备
```

#### Gesture Implementation Requirements / 手势实现技术要求
- **Event Prevention**: 使用 `stopPropagation()` 和 `preventDefault()` 防止手势冲突
- **Priority Management**: 确保 SwipeableItem 手势具有最高优先级
- **Smoothness Guarantee**: 垂直滚动不干扰面板切换手势

### Panel Transformation Logic / 面板变换逻辑

#### Responsive Transformation Distances / 响应式变换距离
```javascript
// 响应式变换距离配置
const transformDistances = {
  ultraNarrow: "< 400px: translate-x-12 (3rem)",
  iPhoneStandard: "401px-768px: translate-x-16 (4rem)",
  iPad: "769px-1199px: translate-x-20 (5rem)", 
  previewEnvironment: "preview: translate-x-12 (最小距离)"
};
```

#### CSS Transform Implementation / CSS 变换实现
```css
/* 面板变换样式 */
.panel-transform-left {
  transform: translateX(var(--transform-distance));
  transition: transform 0.3s ease-in-out;
}

/* 响应式变换 */
@media (max-width: 400px) {
  :root {
    --transform-distance: 3rem;
  }
}

@media (min-width: 401px) and (max-width: 768px) {
  :root {
    --transform-distance: 4rem;
  }
}

@media (min-width: 769px) and (max-width: 1199px) {
  :root {
    --transform-distance: 5rem;
  }
}
```

### Enhanced Device Detection / 设备检测增强

#### Device Detection Logic / 设备检测逻辑
```javascript
const deviceDetection = {
  isInIframe: window !== window.top,
  isFigmaPreview: window.location.href.includes('figma'),
  isPreviewMode: width < 500 && height > 600,
  isNarrowButTall: /* aspect ratio detection */,
  
  // 设备类型检测
  getDeviceType() {
    const width = window.innerWidth;
    if (width < 768) return 'iPhone';
    if (width >= 768 && width < 1200) return 'iPad';
    return 'Mac';
  },
  
  // 预览环境检测
  isPreviewEnvironment() {
    return this.isInIframe || this.isFigmaPreview || this.isPreviewMode;
  }
}
```

#### Environment Adaptation Strategy / 环境适配策略
- **Figma Preview**: 特殊的预览环境适配
- **Iframe Detection**: 识别嵌入环境
- **Aspect Ratio**: 基于宽高比的设备类型判断

### Touch Interaction Technical Implementation / 触摸交互技术实现

#### Swipe Gesture Implementation / 滑动手势实现
```javascript
class SwipeGestureHandler {
  constructor(element, options = {}) {
    this.element = element;
    this.options = {
      threshold: options.threshold || 50,
      restraint: options.restraint || 100,
      allowedTime: options.allowedTime || 300,
      ...options
    };
    
    this.startX = 0;
    this.startY = 0;
    this.startTime = 0;
    
    this.bindEvents();
  }
  
  bindEvents() {
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this));
    this.element.addEventListener('touchmove', this.handleTouchMove.bind(this));
    this.element.addEventListener('touchend', this.handleTouchEnd.bind(this));
  }
  
  handleTouchStart(e) {
    e.stopPropagation();
    const touch = e.changedTouches[0];
    this.startX = touch.clientX;
    this.startY = touch.clientY;
    this.startTime = new Date().getTime();
  }
  
  handleTouchMove(e) {
    e.preventDefault(); // 防止页面滚动
  }
  
  handleTouchEnd(e) {
    e.stopPropagation();
    const touch = e.changedTouches[0];
    const distX = touch.clientX - this.startX;
    const distY = touch.clientY - this.startY;
    const elapsedTime = new Date().getTime() - this.startTime;
    
    if (elapsedTime <= this.options.allowedTime) {
      if (Math.abs(distX) >= this.options.threshold && Math.abs(distY) <= this.options.restraint) {
        if (distX > 0) {
          this.onSwipeRight();
        } else {
          this.onSwipeLeft();
        }
      }
    }
  }
  
  onSwipeLeft() {
    // 显示 Edit + More 按钮
    this.element.classList.add('swiped-left');
    this.showActionButtons();
  }
  
  onSwipeRight() {
    // 快速收藏功能
    this.element.classList.add('swiped-right');
    this.toggleFavorite();
  }
}
```

#### Tactile Feedback Implementation / 触摸反馈实现
```javascript
// 触觉反馈系统
function provideTactileFeedback(type = 'light') {
  if ('vibrate' in navigator) {
    switch(type) {
      case 'light':
        navigator.vibrate(10);
        break;
      case 'medium':
        navigator.vibrate(25);
        break;
      case 'heavy':
        navigator.vibrate(50);
        break;
    }
  }
}
```

### Animation & Transition Effects / 动画与过渡效果

#### Smooth Animation Implementation / 流畅动画实现
```css
/* 面板切换动画 */
.panel {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

/* 按钮显示动画 */
.action-buttons {
  transform: translateX(100%);
  opacity: 0;
  transition: all 0.2s ease-out;
}

.action-buttons.visible {
  transform: translateX(0);
  opacity: 1;
}

/* 收藏心形动画 */
.favorite-heart {
  transition: all 0.2s ease-in-out;
  transform: scale(1);
}

.favorite-heart.animated {
  animation: heartBeat 0.6s ease-in-out;
}

@keyframes heartBeat {
  0% { transform: scale(1); }
  25% { transform: scale(1.2); }
  50% { transform: scale(1.1); }
  75% { transform: scale(1.2); }
  100% { transform: scale(1); }
}
```

#### Performance Optimization / 性能优化
```javascript
// 使用 requestAnimationFrame 优化动画
function smoothAnimation(callback) {
  let ticking = false;
  
  return function(e) {
    if (!ticking) {
      requestAnimationFrame(() => {
        callback(e);
        ticking = false;
      });
      ticking = true;
    }
  };
}
```

### State Management & Synchronization / 状态管理与同步

#### Panel State Management / 面板状态管理
```javascript
class PanelStateManager {
  constructor() {
    this.currentPanel = 'center';
    this.panelHistory = ['center'];
    this.isAnimating = false;
  }
  
  switchToPanel(panelName) {
    if (this.isAnimating) return;
    
    this.isAnimating = true;
    this.currentPanel = panelName;
    this.panelHistory.push(panelName);
    
    // 执行面板切换动画
    this.animateToPanel(panelName).then(() => {
      this.isAnimating = false;
    });
  }
  
  async animateToPanel(panelName) {
    const panels = document.querySelectorAll('.panel');
    
    return new Promise(resolve => {
      panels.forEach(panel => {
        panel.classList.remove('active');
        if (panel.dataset.panel === panelName) {
          panel.classList.add('active');
        }
      });
      
      setTimeout(resolve, 300); // 等待动画完成
    });
  }
}
```

### Preview Environment Handling / 预览环境特殊处理

#### Preview Environment Styles / 预览环境样式适配
```css
/* 预览专用样式 */
.preview-fix {
  width: 100vw !important;
  max-width: none !important;
  min-width: 100% !important;
  overflow-x: hidden;
}

/* Figma 预览特殊处理 */
.figma-preview .panel-overlay {
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(2px);
}

/* 窄屏适配 */
@media (max-width: 450px) {
  .panel-transform-left {
    transform: translateX(3rem);
  }
  
  .hide-in-narrow {
    display: none;
  }
  
  .compact-in-narrow {
    padding: 0.5rem;
    font-size: 0.875rem;
  }
}
```

#### JavaScript Preview Environment Detection / JavaScript 预览环境检测
```javascript
// 预览环境适配
function adaptForPreview() {
  if (deviceDetection.isPreviewEnvironment()) {
    document.body.classList.add('preview-mode');
    
    // 调整触摸区域
    const touchTargets = document.querySelectorAll('[data-touch-target]');
    touchTargets.forEach(target => {
      target.style.minHeight = '48px';
      target.style.minWidth = '48px';
    });
    
    // 禁用某些高级手势
    const advancedGestures = document.querySelectorAll('.advanced-gesture');
    advancedGestures.forEach(element => {
      element.classList.add('gesture-disabled');
    });
  }
}
```

#### iPad Requirements
```
Minimum Supported:
- iPad (9th generation) - A13 Bionic
- iPad Air (4th generation) - A14 Bionic
- iPad Pro (all models with A12X+)
- 4GB RAM, 64GB storage
- iPadOS 16.0+

Recommended:
- iPad Pro with M1/M2 chip
- 8GB+ RAM
- 256GB+ storage
- Apple Pencil support
- iPadOS 17.0+
```

#### macOS Requirements
```
Minimum Supported:
Intel Macs:
- MacBook Pro (2019+)
- MacBook Air (2020+)
- iMac (2019+)
- Mac mini (2018+)

Apple Silicon:
- All M1/M2/M3 Macs
- 8GB RAM
- 256GB storage (10GB free)
- macOS 13.0+

Recommended:
- Apple Silicon Mac
- 16GB+ RAM
- 512GB+ SSD storage
- macOS 14.0+
```

---

## ⚡ Performance Requirements / 性能要求

### Response Time Targets / 响应时间目标

#### Critical Operations (P0)
- **App Launch**: 
  - Cold start: < 3.0 seconds
  - Warm start: < 1.0 second
  - Background to foreground: < 0.5 seconds

- **Content Capture**:
  - Clipboard detection: < 0.2 seconds
  - Content processing: < 2.0 seconds
  - OCR processing: < 5.0 seconds
  - Save to database: < 1.0 second

- **Search Operations**:
  - Text search: < 1.0 second
  - Semantic search: < 3.0 seconds
  - Complex queries: < 5.0 seconds
  - Search suggestions: < 0.3 seconds

#### Important Operations (P1)
- **AI Processing**:
  - Content analysis: < 10.0 seconds
  - Task generation: < 5.0 seconds
  - Semantic tagging: < 3.0 seconds
  - Relationship extraction: < 8.0 seconds

- **Sync Operations**:
  - Small updates: < 2.0 seconds
  - Large files: < 30.0 seconds
  - Conflict resolution: < 5.0 seconds
  - Initial sync: < 120.0 seconds

- **Graph Operations**:
  - Graph rendering: < 3.0 seconds
  - Node exploration: < 1.0 second
  - Path calculation: < 2.0 seconds
  - Layout updates: < 1.5 seconds

### Memory Usage Targets / 内存使用目标

#### Memory Allocation Limits
```swift
// iOS Memory Targets
iPhone (4GB device):
- Baseline usage: < 150MB
- Active processing: < 400MB
- Peak usage: < 600MB

iPhone (6GB+ device):
- Baseline usage: < 200MB
- Active processing: < 500MB
- Peak usage: < 800MB

iPad (8GB+ device):
- Baseline usage: < 250MB
- Active processing: < 700MB
- Peak usage: < 1.2GB

macOS:
- Baseline usage: < 300MB
- Active processing: < 1GB
- Peak usage: < 2GB
```

#### Memory Management Strategy
- **Lazy Loading**: Content loaded on-demand
- **Image Caching**: Intelligent cache with size limits
- **Background Cleanup**: Automatic memory pressure handling
- **Large File Handling**: Streaming for files > 50MB

### Battery Life Targets / 电池续航目标

#### iOS Power Consumption
- **Background Activity**: < 2% battery per hour
- **Active Usage**: < 8% battery per hour
- **AI Processing**: < 15% battery per hour (heavy usage)
- **Sync Operations**: < 5% battery per session

#### Power Optimization Strategies
- **Background App Refresh**: Intelligent scheduling
- **Location Services**: Minimal usage, only when needed
- **Network Activity**: Batch operations, efficient protocols
- **CPU Throttling**: Adaptive processing based on device thermal state

---

## 🏗️ Technical Architecture / 技术架构

### Core Technology Stack / 核心技术栈

#### Apple Platform Technologies
```swift
// UI Framework
SwiftUI 5.0+ (iOS 16+, macOS 13+)
UIKit integration for legacy components
AppKit bridging for macOS-specific features

// Development Language
Swift 5.9+
Objective-C interop for system APIs
C++ for performance-critical algorithms

// Data & Persistence
SwiftData (iOS 17+) / Core Data (fallback)
SQLite for cross-platform compatibility
CloudKit for Apple ecosystem sync
FileManager for local file operations

// Networking & AI
URLSession for HTTP communications
Vision framework for OCR and image analysis
Natural Language framework for text processing
Core ML for on-device AI inference
```

#### Third-Party Dependencies
```json
{
  "ai_services": {
    "openai_api": "GPT-4 for advanced text processing",
    "anthropic_api": "Claude for content analysis (backup)",
    "local_ml": "Core ML models for offline processing"
  },
  "utilities": {
    "sqlite": "3.40+ for cross-platform database",
    "crypto": "CryptoKit for encryption",
    "compression": "Compression framework for data optimization"
  },
  "testing": {
    "xctest": "Native testing framework",
    "snapshot_testing": "UI regression testing"
  }
}
```

### Data Architecture / 数据架构

#### Local-First Storage Strategy
```
┌─────────────────────────────────────────────────────┐
│                 Local Storage Layer                 │
├─────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │   SQLite    │  │ File System  │  │ Vector DB   │ │
│  │ (Metadata)  │  │ (Content)    │  │ (Semantic)  │ │
│  └─────────────┘  └──────────────┘  └─────────────┘ │
├─────────────────────────────────────────────────────┤
│                 Sync Layer (CloudKit)               │
├─────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │ Incremental │  │ Conflict     │  │ Encryption  │ │
│  │ Updates     │  │ Resolution   │  │ at Rest     │ │
│  └─────────────┘  └──────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────┘
```

#### Database Schema Design
```sql
-- Core Content Table
CREATE TABLE content_nodes (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    title TEXT,
    content TEXT,
    metadata JSON,
    created_at TIMESTAMP,
    modified_at TIMESTAMP,
    source_app TEXT,
    file_path TEXT,
    tags JSON,
    embedding BLOB
);

-- Knowledge Graph Relations
CREATE TABLE content_relations (
    id TEXT PRIMARY KEY,
    source_id TEXT REFERENCES content_nodes(id),
    target_id TEXT REFERENCES content_nodes(id),
    relation_type TEXT,
    confidence REAL,
    created_at TIMESTAMP
);

-- Task Management
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT,
    priority INTEGER,
    due_date TIMESTAMP,
    source_content_id TEXT REFERENCES content_nodes(id),
    created_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Full-Text Search Index
CREATE VIRTUAL TABLE content_fts USING fts5(
    title, content, tags,
    content=content_nodes,
    content_rowid=rowid
);
```

### AI/ML Architecture / AI/ML架构

#### On-Device Processing Pipeline
```swift
// Content Analysis Pipeline
struct ContentProcessor {
    // Phase 1: Basic Analysis
    func extractText(from content: CapturedContent) async -> String
    func detectLanguage(_ text: String) -> String
    func extractEntities(_ text: String) -> [Entity]
    
    // Phase 2: Semantic Analysis
    func generateEmbedding(_ text: String) async -> [Float]
    func classifyContent(_ text: String) async -> [ContentType]
    func extractKeyPhrases(_ text: String) async -> [String]
    
    // Phase 3: Knowledge Integration
    func findSimilarContent(_ embedding: [Float]) async -> [ContentNode]
    func extractRelationships(_ content: ContentNode) async -> [Relation]
    func generateTasks(_ content: ContentNode) async -> [TaskSuggestion]
}
```

#### Cloud AI Integration
- **Fallback Strategy**: Local processing first, cloud if needed
- **Rate Limiting**: Intelligent request throttling
- **Cost Management**: Budget controls and usage monitoring
- **Privacy**: On-device processing for sensitive content

---

## 🔒 Security & Privacy / 安全与隐私

### Data Protection Requirements / 数据保护要求

#### Encryption Standards
- **At Rest**: AES-256 encryption for local files
- **In Transit**: TLS 1.3 for all network communications
- **Keys**: Hardware-backed keychain storage
- **Backup**: End-to-end encrypted CloudKit backups

#### Privacy Compliance
```swift
// Data Collection Minimization
struct PrivacyPolicy {
    // Local Processing First
    static let localFirst = true
    
    // No Personal Data Collection
    static let collectsPersonalData = false
    
    // Optional Analytics
    static let analyticsOptIn = true
    
    // GDPR Compliance
    static let dataExportSupport = true
    static let dataDeleteSupport = true
}
```

### Security Implementation / 安全实施

#### Authentication & Authorization
- **Local Authentication**: Face ID, Touch ID, passcode
- **Team Access**: Role-based permissions
- **API Security**: OAuth 2.0 + JWT tokens
- **Session Management**: Automatic timeout and refresh

#### Threat Mitigation
- **Input Validation**: All user inputs sanitized
- **SQL Injection**: Parameterized queries only
- **XSS Prevention**: Content sanitization
- **Network Security**: Certificate pinning for APIs

---

## 🔧 Development Constraints / 开发约束

### Technical Limitations / 技术限制

#### Platform Constraints
```swift
// iOS/iPadOS Limitations
- Background processing: 30 seconds max
- Memory pressure: Automatic app termination
- Network access: Background app refresh dependency
- File access: Sandbox restrictions

// macOS Specific
- Sandboxing: App Store distribution requirements
- Privacy permissions: Camera, microphone, file access
- Notarization: Code signing requirements
- Gatekeeper: Security policy compliance
```

#### Apple Store Guidelines Compliance
- **Content Policy**: No inappropriate content processing
- **Privacy Requirements**: Clear permission requests
- **Performance Standards**: No app crashes or hangs
- **Accessibility**: Full VoiceOver and keyboard support

### Development Process Constraints / 开发流程约束

#### Code Quality Requirements
```swift
// Testing Coverage
- Unit tests: > 80% code coverage
- Integration tests: Critical path coverage
- UI tests: Key user journey validation
- Performance tests: Regression prevention

// Code Standards
- Swift style guide compliance
- SwiftLint integration
- Documentation requirements
- Security audit requirements
```

#### Release Process
- **Beta Testing**: TestFlight with 100+ users
- **Performance Monitoring**: Crash reporting and analytics
- **Gradual Rollout**: Staged release across regions
- **Rollback Plan**: Quick revert capability

---

## 📊 Monitoring & Analytics / 监控与分析

### Performance Monitoring / 性能监控

#### Key Metrics
```swift
// App Performance
- Launch time tracking
- Memory usage monitoring
- CPU usage patterns
- Battery consumption analysis

// Feature Usage
- Content capture frequency
- Search query patterns
- AI feature utilization
- Task completion rates

// Quality Metrics
- Crash rate (< 0.1%)
- ANR rate (< 0.05%)
- User satisfaction (NPS > 50)
- Retention rate (60%+ at 30 days)
```

#### Monitoring Tools
- **Xcode Instruments**: Detailed performance profiling
- **MetricKit**: System performance metrics
- **Firebase Analytics**: User behavior tracking (privacy-first)
- **Custom Telemetry**: Feature-specific metrics

### Error Handling & Logging / 错误处理与日志记录

#### Logging Strategy
```swift
// Log Levels
enum LogLevel {
    case debug      // Development only
    case info       // General information
    case warning    // Potential issues
    case error      // Recoverable errors
    case critical   // App-breaking errors
}

// Privacy-Safe Logging
- No personal content in logs
- User identifiers hashed
- Local log rotation
- Optional crash reporting
```

---

## 🔄 Scalability & Future-Proofing / 可扩展性与面向未来

### Scalability Requirements / 可扩展性要求

#### Data Scale Targets
- **Individual Users**: 100,000+ content items
- **Team Workspaces**: 1,000+ concurrent users
- **Enterprise**: 10,000+ users per organization
- **Global Scale**: 1M+ total users (Phase 3+)

#### Architecture Scalability
```swift
// Modular Design
protocol ContentProcessor {
    func process(_ content: CapturedContent) async throws -> ProcessedContent
}

protocol StorageProvider {
    func save(_ content: ProcessedContent) async throws
    func search(_ query: SearchQuery) async throws -> [ContentNode]
}

// Plugin Architecture (Future)
protocol SnapNotionPlugin {
    func initialize(context: PluginContext) async
    func processContent(_ content: ContentNode) async -> PluginResult
}
```

### Future Technology Integration / 未来技术集成

#### Emerging Technologies
- **AR/VR Support**: visionOS integration planning
- **Advanced AI**: GPT-5+ model integration
- **Blockchain**: Decentralized storage options
- **Edge Computing**: Local AI model improvements

#### API Evolution Strategy
- **Versioning**: Semantic versioning for all APIs
- **Backward Compatibility**: Minimum 2 version support
- **Migration Tools**: Automated data migration
- **Documentation**: Comprehensive API documentation

---

## ✅ Acceptance Criteria / 验收标准

### Technical Acceptance Criteria / 技术验收标准

#### Performance Benchmarks
- [ ] App launches within 3 seconds on minimum hardware
- [ ] Content capture processes within 2 seconds
- [ ] Search returns results within 1 second for 90% of queries
- [ ] Memory usage stays within platform limits
- [ ] Battery drain < 8% per hour of active use

#### Quality Assurance
- [ ] Zero critical security vulnerabilities
- [ ] Crash rate < 0.1% across all platforms
- [ ] 99.9% uptime for core features
- [ ] All accessibility requirements met
- [ ] App Store review guidelines compliance

#### Feature Completeness
- [ ] All P0 features implemented and tested
- [ ] Cross-platform sync working reliably
- [ ] Offline functionality fully operational
- [ ] Data export/import capabilities verified
- [ ] Multi-language support functional

---

*Last Updated: 2025-08-22*  
*Version: 1.0.0*  
*Next Review: Post-MVP Release*