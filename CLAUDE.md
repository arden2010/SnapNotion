# SnapNotion - Intelligent Content Management System 
## 智能内容管理系统

---

## Project Overview / 项目概述

SnapNotion is a **local-first intelligent content management system** designed from first principles, combining:
- **Evernote's capture excellence** for comprehensive content collection
- **AI-powered organization** for intelligent content structuring  
- **Semantic search capabilities** for knowledge discovery

The system transforms passive information consumption into active knowledge creation through intelligent automation, serving as both a personal knowledge brain and collaborative workspace.

SnapNotion 是一款基于第一性原理设计的本地优先智能内容管理系统，将**印象笔记的捕获能力** + **AI智能组织** + **语义搜索**结合，通过智能自动化将被动信息消费转化为主动知识创造。

### 🎯 Product Vision / 产品愿景

**个人模式**: Functions like Obsidian as a "personal knowledge brain" ensuring data preservation and long-term security  
**团队模式**: Operates like Notion as a "collaborative workspace" supporting projects and workflows  
**跨界融合**: Serves dual roles as both "repository" (like Evernote) and "whiteboard/outline tool" (like MindMeister)

### 🔄 Six Core Capabilities (First Principles) / 六大核心能力

#### 1. 收集 (Capture)
- Rapid capture of text, web pages, PDFs, images, voice recordings
- Intelligent clipboard monitoring with auto-classification
- Multi-format content processing with OCR and AI analysis

#### 2. 组织 (Organize)  
- Outline-based (tree structure) + Database-style (multi-dimensional) + Bidirectional linking (network)
- AI-powered auto-tagging and categorization
- Semantic relationship extraction and clustering

#### 3. 检索 (Retrieve)
- Full-text search + OCR + AI semantic search
- Natural language query understanding
- Context-aware recommendations and knowledge discovery

#### 4. 应用 (Apply)
- Transform knowledge into writing, tasks, and project management
- Automatic task generation from captured content
- AI writing assistant with knowledge base integration

#### 5. 沉淀 (Preserve)
- Local-first storage ensuring user data ownership
- Offline-first operation with cloud sync capabilities
- Long-term data preservation and accessibility

#### 6. 协作 (Collaborate)
- Multi-user real-time editing with conflict resolution
- Granular permission control and workspace management
- Enterprise-grade knowledge base capabilities

---

## 🎨 Core UI/UX Architecture / 核心UI/UX架构

### Optimized 3-Tab Navigation System / 优化的三Tab导航系统

#### Main Navigation Structure / 主导航结构
```
┌─────────────────────────────────────────────────────────┐
│                   Top Navigation                        │
│  [📥 Inbox]     [📁 Organize]     [🧠 Insights]        │
└─────────────────────────────────────────────────────────┘
│                                                         │
│                 Content Area                            │
│                                                         │
│                                               [+] FAB   │ ← Floating Action Button
├─────────────────────────────────────────────────────────┤
│    [Library] [Favorites] [Tasks]          (Organize)    │ ← Sub-navigation (Organize only)
└─────────────────────────────────────────────────────────┘
```

#### Phoenix Branding / 凤凰品牌设计
- **品牌图标**: 橙色凤凰图标 (120px, h-30 w-30)
- **主色调**: Phoenix Orange #FF9933 - Applied to active states and FAB
- **设计理念**: 象征智能转换与知识重生

### Enhanced Three-Tab System / 增强的三Tab系统

#### **Tab 1: 📥 Inbox** (Gmail-style Content Hub)
- **Purpose**: Gmail-style inbox for all captured content
- **Icon**: `tray.fill` / `tray` (active/inactive)
- **Features**: 
  - All content types mixed together chronologically
  - Floating Action Button (FAB) for content capture
  - Gmail-style list interface with swipe actions
- **Color Theme**: Clean, neutral with Phoenix Orange accents

#### **Tab 2: 📁 Organize** (Content Organization Hub)
- **Purpose**: Organized content by categories with sub-navigation
- **Icon**: `folder.fill` / `folder` (active/inactive)
- **Features**:
  - **Compact Sub-tabs**: Library, Favorites, Tasks (grouped on left)
  - **12px spacing** between sub-tabs for optimal touch targets
  - **Consistent FAB** positioning (bottom-right, same as Inbox)
  - **No overlap** between sub-tabs and FAB
- **Sub-Navigation**:
  - **📚 Library**: `books.vertical.fill` / `books.vertical`
  - **❤️ Favorites**: `heart.fill` / `heart` 
  - **✅ Tasks**: `checkmark.circle.fill` / `checkmark.circle`

#### **Tab 3: 🧠 Insights** (Knowledge Connections)
- **Purpose**: Knowledge graph visualization and AI insights
- **Icon**: `brain.head.profile` (static icon)
- **Features**:
  - Interactive knowledge graph with node exploration
  - Graph controls (layout, connection strength, node size)
  - Node detail overlays with connection information
- **Color Theme**: Purple network visualization theme

### Consistent Floating Action Button (FAB) / 一致的悬浮操作按钮

#### FAB Design Specifications / FAB设计规范
- **Size**: 56×56px circular button
- **Position**: Bottom-right corner (20px margin from edges)
- **Color**: Phoenix Orange #FF9933 background with white icon
- **Icon**: `plus` SF Symbol (title2 font size, medium weight)
- **Shadow**: `black.opacity(0.3)`, radius: 4px, offset: (0, 2)
- **Consistency**: Same position and styling across all main tabs

#### FAB Content Capture Options / FAB内容捕获选项
When tapped, FAB opens `AddContentSheet` with 6 capture methods:
1. **📸 Camera**: Take photo or scan document (`camera` icon, blue theme)
2. **📷 Photo Library**: Choose from photos (`photo` icon, green theme)  
3. **📝 Text Note**: Create new text note (`doc.text` icon, orange theme)
4. **🔗 Web Link**: Save website or URL (`link` icon, purple theme)
5. **📋 From Clipboard**: Paste clipboard content (`doc.on.clipboard` icon, red theme)
6. **📁 Import File**: Import PDF, document, image (`square.and.arrow.down` icon, indigo theme)

### Enhanced Interaction Design / 增强的交互设计

#### Tab Navigation / Tab导航
- **Primary Tabs**: Native iOS TabView with bottom tab bar
- **Sub-tabs (Organize)**: Custom compact HStack with 12px spacing
- **Active States**: Phoenix Orange color for selected tabs
- **Touch Targets**: Minimum 44×44pt for accessibility

#### Content Item Operations / 内容项目操作
- **👉 Right Swipe**: 快速收藏/取消收藏 (红色心形反馈)
- **👈 Left Swipe**: 显示编辑+更多按钮 (蓝色Edit + 紫色More)
- **Tap Gesture**: Navigate to content detail view
- **Long Press**: Context menu with quick actions

#### Responsive Design / 响应式设计
```swift
// SwiftUI Responsive Breakpoints
@Environment(\.horizontalSizeClass) var horizontalSizeClass
@Environment(\.verticalSizeClass) var verticalSizeClass

// Layout Adaptations
iPhone: {
  .compact width + .regular height
  // Single-column layout, bottom tabs, optimized FAB positioning
}

iPad: {
  .regular width + .regular height  
  // Enhanced spacing, larger touch targets, split-view ready
}

Mac: {
  .regular width + .compact height (via Catalyst)
  // Desktop-optimized controls, keyboard shortcuts, menu bar
}
```

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

### Local-First + AI Hybrid Architecture / 本地优先+AI混合架构

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────┤
│  UI Layer (SwiftUI - iOS/macOS/Catalyst)                   │
├─────────────────────────────────────────────────────────────┤
│  Content Processing Pipeline                                │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐│
│  │ Input Queue │→ │ Local AI     │→ │ Background Sync     ││
│  │             │  │ Processing   │  │ Queue               ││
│  └─────────────┘  └──────────────┘  └─────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│  Storage Layer                                              │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐│
│  │ SQLite      │  │ Vector Store │  │ File Storage        ││
│  │ (Metadata)  │  │ (Embeddings) │  │ (Original Content)  ││
│  └─────────────┘  └──────────────┘  └─────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   CLOUD SERVICES                           │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐│
│  │ AI Services │  │ Sync Service │  │ Backup Storage      ││
│  │ (Heavy      │  │ (CRDTs)      │  │ (Encrypted)         ││
│  │ Processing) │  │              │  │                     ││
│  └─────────────┘  └──────────────┘  └─────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Database Schema Design / 数据库架构设计

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

---

## 📋 Feature Development Roadmap / 功能开发路线图

### ✅ Current Implementation Status (2025-08-31) / 当前实现状态

#### **Phase 1: Foundation & UI Architecture - COMPLETED** ✅
**Focus**: Core navigation and interface architecture

#### ✅ **Completed Features:**
- [x] ✅ **Optimized 3-Tab Navigation System**: Inbox, Organize, Insights
- [x] ✅ **Consistent FAB Design**: 56×56px floating action button across all tabs
- [x] ✅ **Gmail-style Content Interface**: Clean list views with swipe actions
- [x] ✅ **Compact Sub-navigation**: Library/Favorites/Tasks with 12px spacing
- [x] ✅ **AddContentSheet Modal**: 6 content capture methods with themed icons
- [x] ✅ **Knowledge Graph Visualization**: Interactive nodes with controls
- [x] ✅ **Phoenix Orange Branding**: Consistent color theme throughout
- [x] ✅ **SwiftUI Architecture**: Modern iOS/macOS compatible codebase
- [x] ✅ **Build System Integration**: Xcode project with successful compilation

#### 🎯 **Key Architecture Decisions Made:**
- **Navigation Simplification**: From 5-tab to 3-tab system for better UX
- **FAB Consistency**: Same position/styling across tabs (not tab-integrated)
- **Content Organization**: Hierarchical structure (main → sub-navigation)
- **Design Language**: Gmail-inspired simplicity with Phoenix Orange accents

### Phase 2: Content Processing & AI Integration (Q4 2025)
**Focus**: Content capture, processing, and intelligent organization

#### Key Deliverables:
- [ ] 🎯 Multi-format content capture implementation
- [ ] 🎯 OCR图像文字识别
- [ ] 🎯 AI内容分析与自动标签
- [ ] 🎯 剪贴板智能监听与内容捕获
- [ ] 🎯 AI任务自动生成与优先级判断
- [ ] 🎯 本地存储与搜索基础
- [ ] 🎯 Core Data integration with CloudKit sync

#### P0 Features (Must-Have for V1.0):
- Functional content capture system
- Basic AI-powered organization
- Local storage with cloud backup
- Search and retrieval capabilities
- Task generation from captured content

### Phase 3: Knowledge Intelligence (Q1 2026)
**Focus**: Advanced AI and knowledge management

#### Key Deliverables:
- [ ] 🎯 OCR图像文字识别
- [ ] 🎯 AI内容分析与自动标签
- [ ] 🎯 知识图谱基础系统
- [ ] 🎯 语义搜索引擎
- [ ] Semantic search and recommendations
- [ ] Knowledge graph visualization
- [ ] Advanced AI content enhancement
- [ ] Team workspace creation

#### P1 Features (Should-Have for V2.0):
- Knowledge graph visualization
- Advanced AI content enhancement
- Semantic search improvements
- Advanced task management
- Cross-platform optimization

### Phase 3: Application & Integration (Q4 2025)
**Focus**: 知识网络与协作

#### Key Deliverables:
- [ ] 🎯 双向链接与语义关联
- [ ] 🎯 知识聚类与主题识别
- [ ] 🎯 团队工作空间创建
- [ ] 🎯 实时协作编辑
- [ ] AI writing assistant and content generation
- [ ] Project management integration
- [ ] Plugin ecosystem and third-party integrations
- [ ] Enterprise-grade features

### Phase 4: Ecosystem & Scale (2026)
**Focus**: 智能应用与生态

#### Key Deliverables:
- [ ] 🎯 AI写作助手与内容生成
- [ ] 🎯 项目管理集成
- [ ] 🎯 插件生态与第三方集成
- [ ] 🎯 企业级功能完善
- [ ] Multi-language support expansion
- [ ] Advanced collaboration features
- [ ] API ecosystem for developers
- [ ] Enterprise deployment options

---

## 📱 Platform-Specific Requirements / 平台特性要求

### iOS-Specific Features / iOS特定功能

#### iPhone Optimizations / iPhone优化
- **Thumb Zone Design**: Critical UI elements within thumb reach
- **Quick Actions**: 3D Touch/Haptic Touch shortcuts from home screen
- **Siri Integration**: Voice commands for content capture and search
- **Widget Support**: Today view widgets for quick capture and recent items
- **Background Processing**: Efficient clipboard monitoring with minimal battery impact
- **Accessibility**: Full VoiceOver support and Dynamic Type compatibility

#### iPad Enhancements / iPad增强功能
- **Split View Support**: Multi-app workflows with drag-and-drop
- **Apple Pencil Integration**: Handwriting recognition and sketch annotation
- **External Keyboard**: Full keyboard shortcut support
- **Stage Manager**: Efficient window management and multitasking
- **Camera Integration**: Document scanning with perspective correction
- **Multitasking**: Picture-in-picture for video content processing

### macOS-Specific Features / macOS特定功能

#### Desktop-Class Functionality / 桌面级功能
- **Menu Bar Integration**: Global shortcuts and status item
- **Multiple Windows**: Separate windows for different workspaces
- **Advanced Keyboard Shortcuts**: Professional-grade hotkey system
- **Dock Integration**: Badge notifications and quick actions
- **System Integration**: Spotlight integration and Services menu
- **Touch Bar Support**: Context-sensitive controls (where available)

#### Professional Tools / 专业工具
- **Advanced Search**: Powerful query builder with saved searches
- **Batch Operations**: Multi-select actions across large datasets
- **Export Tools**: Professional-grade export options and automation
- **File System Integration**: Native file management and organization
- **External Display**: Multi-monitor support for graph visualization
- **Automation**: AppleScript and Shortcuts app integration

### Device Requirements / 设备要求

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

---

## 🌐 Internationalization & Localization / 国际化与本地化

### Language Support / 语言支持

#### Phase 1 Languages (MVP) / 第一阶段语言
- **Chinese (Simplified)** - zh-CN: Primary target market
- **English** - en-US: International requirement

#### Phase 2 Languages (V2.0) / 第二阶段语言
- **Chinese (Traditional)** - zh-TW: Hong Kong, Taiwan, Macau
- **Japanese** - ja-JP: Japanese market expansion
- **Korean** - ko-KR: Korean market expansion

#### Phase 3 Languages (V3.0) / 第三阶段语言
- **French** - fr-FR: European market
- **German** - de-DE: DACH region
- **Spanish** - es-ES: Spanish-speaking markets

### Localization Implementation / 本地化实现

#### SwiftUI Localization Architecture
```swift
// String Localization Management
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// Localization Manager
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String = "zh-CN"
    
    func setLanguage(_ code: String) {
        currentLanguage = code
        UserDefaults.standard.set(code, forKey: "app_language")
        NotificationCenter.default.post(name: .languageChanged, object: code)
    }
}
```

#### String Key Naming Convention
```
// Module.Function.Element
"dashboard.greeting.title"          // Dashboard greeting title
"task.create.button"               // Create task button
"content.capture.description"       // Content capture description
"settings.language.selection"       // Language selection setting
"error.network.connection"         // Network connection error
```

---

## 🏗️ Current Implementation Architecture / 当前实现架构

### ✅ **Implemented Components** / 已实现组件

#### **UI Layer - SwiftUI Views** / UI层 - SwiftUI视图
```swift
// Main Navigation Structure
ContentView.swift                    // ✅ 3-tab TabView container
├── MainContentView.swift            // ✅ Tab 1: Inbox (Gmail-style)
├── ContentTypesView.swift           // ✅ Tab 2: Organize + Sub-tabs
│   ├── LibraryContentView           // ✅ Library sub-tab
│   ├── FavoritesContentView         // ✅ Favorites sub-tab  
│   └── TasksContentView             // ✅ Tasks sub-tab
└── KnowledgeGraphView.swift         // ✅ Tab 3: Insights (Graph viz)

// Shared Components
AddContentSheet.swift                // ✅ FAB modal (6 capture options)
ContentRowView.swift                 // ✅ Content list item with swipe actions
TaskRowView.swift                    // ✅ Task item with completion toggle
```

#### **Data Models & ViewModels** / 数据模型和视图模型
```swift
// Core Models
ContentItem.swift                    // ✅ Content data model
SimpleTaskItem.swift                 // ✅ Task data model  
GraphNode.swift                      // ✅ Knowledge graph node model

// ViewModels
ContentViewModel.swift               // ✅ Content management logic
TaskManager.swift                    // ✅ Task CRUD operations
GraphManager.swift                   // ✅ Graph visualization logic
```

#### **Design System Implementation** / 设计系统实现
```swift
// Color Extensions
extension Color {
    static let phoenixOrange = Color(red: 1.0, green: 0.6, blue: 0.2)  // #FF9933
}

// FAB Specifications (Consistent across all tabs)
.frame(width: 56, height: 56)
.background(Color.phoenixOrange)
.clipShape(Circle())
.shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
.padding(.trailing, 20)
.padding(.bottom, 20)

// Tab Spacing (Organize sub-tabs)
HStack(spacing: 12) { /* Compact 12px spacing */ }
```

#### **Build & Integration Status** / 构建和集成状态
- ✅ **Xcode Project**: Successfully compiles with zero errors
- ✅ **SwiftUI Compatibility**: iOS 16+, macOS 13+ ready
- ✅ **Git Integration**: All changes committed and pushed to GitHub
- ⚠️ **Minor Warnings**: Swift 6 concurrency warnings (non-blocking)

### 🚧 **Next Development Priorities** / 下一步开发重点
1. **Content Capture Implementation**: Make FAB capture methods functional
2. **Core Data Integration**: Replace mock data with persistent storage
3. **AI Processing Pipeline**: Implement content analysis and task generation
4. **CloudKit Sync**: Add cross-device synchronization

---

## 🔄 Multi-App Ecosystem Architecture / 多应用生态架构

### Strategic Vision / 战略愿景

SnapNotion 将作为**中央知识枢纽**，为围绕其构建的专业化应用程序提供数据和智能服务，形成强大的生产力工具生态系统。

**SnapNotion as Central Knowledge Hub** - serving specialized productivity apps with data and intelligence services to create a powerful ecosystem of interconnected tools.

#### Ecosystem Architecture / 生态系统架构
```
┌─────────────────────────────────────────────────────────┐
│                    SnapNotion Core                      │
│              (Central Knowledge Hub)                    │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │Content  │  │AI       │  │Knowledge│  │Task     │   │
│  │Storage  │  │Engine   │  │Graph    │  │Engine   │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
│                                                       │
│           Universal Export API & Hook System           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │Export   │  │Webhook  │  │Real-time│  │Security │   │
│  │Engine   │  │System   │  │Sync     │  │Gateway  │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
└─────────────────────┬───────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│TaskMaster   │ │WriteFlow    │ │InsightDash  │
│(Task Mgmt)  │ │(Writing)    │ │(Analytics)  │
│             │ │             │ │             │
│• GTD Flows  │ │• AI Writing │ │• Productivity│
│• Time Track │ │• Publishing │ │• Insights   │
│• Collab     │ │• Research   │ │• Reports    │
└─────────────┘ └─────────────┘ └─────────────┘

        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│StudyMate    │ │BusinessHub  │ │CreativeKit  │
│(Learning)   │ │(Enterprise) │ │(Design)     │
│             │ │             │ │             │
│• Note-taking│ │• Team Collab│ │• Mood Board │
│• Flashcards │ │• Compliance │ │• Asset Mgmt │
│• Progress   │ │• Reporting  │ │• Inspiration│
└─────────────┘ └─────────────┘ └─────────────┘
```

### Universal Data Export Infrastructure / 通用数据导出基础设施

#### Core Export Architecture / 核心导出架构
```swift
// Primary Export Protocol
protocol SnapNotionDataExporter {
    // Content Export
    func exportContent(filter: ContentFilter) async -> ExportedData
    func exportContentStream(filter: ContentFilter) -> AsyncStream<ContentNode>
    
    // Knowledge Graph Export  
    func exportKnowledgeGraph(scope: GraphScope) async -> GraphExport
    func exportSemanticRelations(nodeIds: [UUID]) async -> [SemanticRelation]
    
    // Task & Workflow Export
    func exportTasks(filter: TaskFilter) async -> TaskExport
    func exportTaskTemplates() async -> [TaskTemplate]
    
    // AI & Analytics Export
    func exportAIInsights(contentIds: [UUID]) async -> AIInsightsExport
    func exportUsageAnalytics(timeRange: DateInterval) async -> AnalyticsExport
    
    // Real-time Subscriptions
    func subscribeToChanges(scope: SubscriptionScope) -> AsyncStream<DataUpdate>
    func createWebhook(endpoint: URL, events: [EventType]) async -> WebhookHandle
}

// Universal Data Schema
struct UniversalContentNode: Codable, Sendable {
    let id: UUID
    let title: String
    let content: String
    let contentType: UniversalContentType
    let tags: [String]
    let aiMetadata: AIMetadata?
    let relationships: [UniversalRelation]
    
    // Temporal data
    let createdAt: ISO8601Date
    let modifiedAt: ISO8601Date
    let accessedAt: ISO8601Date?
    
    // Source tracking
    let sourceApp: String = "SnapNotion"
    let schemaVersion: String = "1.0"
    let exportedAt: ISO8601Date
    let syncToken: String
    
    // Cross-platform compatibility
    let platformMetadata: [String: AnyCodable]
}

// Hook System for Extensions
protocol ContentProcessingHook: Sendable {
    func willExportContent(_ content: ContentNode) async -> ContentNode?
    func didExportContent(_ exported: UniversalContentNode) async -> UniversalContentNode
    func canExportToApp(_ appId: String) async -> Bool
}
```

#### Multi-Format Export Support / 多格式导出支持
```swift
// Export Format Registry
enum ExportFormat: String, CaseIterable {
    case universalJSON = "universal-json"      // Default structured format
    case markdown = "markdown"                 // Human-readable format
    case taskPaper = "taskpaper"              // Plain text task format
    case mindMap = "freemind"                 // XML mind map format
    case csv = "csv"                          // Tabular data format
    case rdf = "rdf-xml"                      // Semantic web format
    case opml = "opml"                        // Outline format
    
    var mimeType: String {
        switch self {
        case .universalJSON: return "application/vnd.snapnotion+json"
        case .markdown: return "text/markdown"
        case .csv: return "text/csv"
        // ... other cases
        }
    }
}

// Format Transformation Pipeline
class ExportTransformer {
    func transform<T: Exportable>(_ data: T, to format: ExportFormat) async throws -> Data
    func registerCustomFormat(_ format: CustomExportFormat)
    func validateExportedData(_ data: Data, format: ExportFormat) async -> ValidationResult
}
```

### Cross-App Communication Protocols / 跨应用通信协议

#### URL Scheme & Deep Linking / URL方案和深度链接
```swift
// SnapNotion URL Schemes
enum SnapNotionURL {
    case exportContent(filter: String, format: ExportFormat)
    case shareKnowledgeGraph(nodeId: UUID, depth: Int)
    case requestTaskSync(appId: String, lastSync: Date?)
    case executeQuery(query: String, format: ExportFormat)
    case subscribeUpdates(webhook: URL, events: [EventType])
    
    var url: URL {
        switch self {
        case .exportContent(let filter, let format):
            return URL(string: "snapnotion://api/export/content?filter=\(filter)&format=\(format.rawValue)")!
        case .shareKnowledgeGraph(let nodeId, let depth):
            return URL(string: "snapnotion://api/graph/share/\(nodeId)?depth=\(depth)")!
        // ... other implementations
        }
    }
}

// Bidirectional App Communication
protocol CrossAppCommunicator {
    func sendDataToApp(_ appId: String, data: ExportedData) async throws
    func receiveDataFromApp(_ appId: String) async throws -> ImportedData
    func establishSyncChannel(with appId: String) async throws -> SyncChannel
}
```

#### Shared Data Container / 共享数据容器
```swift
// Secure Inter-App Data Sharing
class SharedDataManager {
    private let containerURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.snapnotion.ecosystem")
    
    // High-performance data sharing
    func writeSharedData<T: Codable>(_ data: T, to path: String, 
                                   compression: CompressionType = .lz4) async throws
    func readSharedData<T: Codable>(_ type: T.Type, from path: String) async throws -> T
    
    // Real-time change observation
    func observeChanges(at path: String) -> AsyncStream<FileSystemEvent>
    func createSyncedDatabase(name: String) async throws -> SharedDatabase
    
    // Security & Permissions
    func grantAccess(to appId: String, for resource: String, 
                    level: AccessLevel, expiry: Date?) async throws
    func revokeAccess(from appId: String, for resource: String) async throws
}
```

### Strategic Development Roadmap / 战略开发路线图

#### **Phase 2: Export Infrastructure (Q4 2025)** / 第二阶段：导出基础设施
**Focus**: Building the foundation for multi-app ecosystem

##### Key Deliverables:
- [ ] 🎯 **Universal Data Schema**: Cross-platform compatible format design
- [ ] 🎯 **Basic Export API**: JSON/Markdown export with filtering
- [ ] 🎯 **App Groups Setup**: Secure inter-app data sharing container
- [ ] 🎯 **URL Scheme Handlers**: Deep linking and app-to-app communication
- [ ] 🎯 **Export Hook System**: Extensible content processing hooks
- [ ] 🎯 **Format Transformation**: Multi-format export pipeline
- [ ] 🎯 **Security Framework**: Access control and permission system

##### P0 Features (Must-Have for Export MVP):
- Universal content export (JSON format)
- Basic task synchronization
- Secure app group data sharing
- URL scheme communication
- Export permission controls

#### **Phase 3: Real-time Ecosystem (Q1 2026)** / 第三阶段：实时生态系统
**Focus**: Advanced integration and real-time synchronization

##### Key Deliverables:
- [ ] 🎯 **Real-time Sync Engine**: Live data updates between apps
- [ ] 🎯 **Webhook System**: Event-driven notifications for external apps
- [ ] 🎯 **SDK Development**: Third-party integration libraries (iOS/macOS)
- [ ] 🎯 **GraphQL API**: Flexible query interface for external apps
- [ ] 🎯 **Change Tracking**: Efficient incremental sync and conflict resolution
- [ ] 🎯 **Performance Optimization**: Caching and data streaming
- [ ] 🎯 **Developer Tools**: API testing and debugging utilities

##### P1 Features (Should-Have for Advanced Integration):
- Real-time knowledge graph updates
- Advanced query capabilities (GraphQL)
- Batch data operations
- Custom webhook event types
- API rate limiting and quotas

#### **Phase 4: Platform Ecosystem (Q2 2026)** / 第四阶段：平台生态系统
**Focus**: Full ecosystem platform with marketplace and governance

##### Key Deliverables:
- [ ] 🎯 **Developer Portal**: Documentation, SDKs, and API reference
- [ ] 🎯 **App Marketplace**: Discovery and distribution platform
- [ ] 🎯 **Revenue Sharing**: Monetization framework for ecosystem apps
- [ ] 🎯 **Enterprise Features**: Advanced security, compliance, audit logs
- [ ] 🎯 **Analytics Platform**: Usage insights and performance monitoring
- [ ] 🎯 **Governance System**: API versioning, deprecation, migration tools
- [ ] 🎯 **Community Support**: Forums, tutorials, best practices

##### Enterprise Features (Large-scale Deployment):
- Multi-tenant data isolation
- Advanced audit and compliance reporting
- Custom deployment and white-labeling
- Enterprise SSO integration
- Advanced analytics and reporting

### Ecosystem App Concepts / 生态应用概念

#### **TaskMaster** - Advanced Task Management
```swift
// Specialized GTD implementation using SnapNotion data
Features:
- Import AI-generated tasks from SnapNotion content analysis
- Advanced project management with knowledge graph integration
- Time tracking with automatic context switching
- Team collaboration with shared knowledge base
- Custom workflow automation based on content triggers
```

#### **WriteFlow** - AI-Powered Writing Assistant
```swift
// Intelligent writing app leveraging SnapNotion's knowledge base
Features:
- Research assistant using SnapNotion's content database
- AI outline generation from knowledge graph relationships
- Automatic citation and source tracking
- Multi-format publishing (blog, academic, social media)
- Real-time fact-checking against knowledge base
```

#### **InsightDash** - Productivity Analytics
```swift
// Personal productivity intelligence platform
Features:
- Cross-app productivity metrics and insights
- Habit formation tracking based on content patterns
- AI-powered productivity recommendations
- Goal tracking with knowledge-based milestone suggestions
- Team productivity benchmarking and optimization
```

#### **StudyMate** - Learning Management System
```swift
// Education-focused app using SnapNotion's AI capabilities
Features:
- Automatic flashcard generation from captured content
- Spaced repetition system with knowledge graph optimization
- Study session planning based on content relationships
- Progress tracking with adaptive learning algorithms
- Collaborative study groups with shared knowledge bases
```

### Business Model & Revenue Streams / 商业模式和收入流

#### **Platform Revenue Model**
1. **API Usage Fees**: Tiered pricing based on data export volume
2. **Premium Integrations**: Advanced features for ecosystem apps
3. **Enterprise Licensing**: Custom deployments and white-labeling
4. **Marketplace Commission**: Revenue sharing from ecosystem app sales
5. **Professional Services**: Custom integration and development services

#### **Ecosystem Growth Strategy**
- **Developer Incentives**: Revenue sharing and technical support
- **Strategic Partnerships**: Integration with major productivity platforms
- **Open Source Components**: Community-driven development
- **Academic Program**: Research partnerships and educational use cases

---

## 📊 Project Structure / 项目结构

```
SnapNotion/
├── src/
│   ├── Shared/                        # Cross-platform shared code
│   │   ├── Models/
│   │   │   ├── Core/
│   │   │   │   ├── ContentNode.swift           # Content node model
│   │   │   │   ├── TaskNode.swift              # Task data model
│   │   │   │   ├── ProjectNode.swift           # Project node model
│   │   │   │   └── KnowledgeNode.swift         # Knowledge node interface
│   │   │   ├── Knowledge/
│   │   │   │   ├── KnowledgeGraph.swift        # Knowledge graph core
│   │   │   │   ├── SemanticRelation.swift      # Semantic relation model
│   │   │   │   ├── KnowledgeCluster.swift      # Knowledge clustering
│   │   │   │   └── ContextMetadata.swift       # Context metadata
│   │   │   ├── Graph/
│   │   │   │   ├── GraphEngine.swift           # Graph engine core
│   │   │   │   ├── BiDirectionalLink.swift     # Bidirectional links
│   │   │   │   └── GraphVisualization.swift    # Graph visualization data
│   │   │   └── Collaboration/
│   │   │       ├── TeamWorkspace.swift         # Team workspace
│   │   │       ├── CollaborationSession.swift  # Collaboration session
│   │   │       └── PermissionModel.swift       # Permission management
│   │   ├── Services/
│   │   │   ├── Core/
│   │   │   │   ├── ContentCaptureManager.swift # Content capture manager
│   │   │   │   ├── TaskAutoGenerator.swift     # Automatic task generator
│   │   │   │   ├── TaskStateManager.swift      # Task state manager
│   │   │   │   └── DataExportService.swift     # Data export service
│   │   │   ├── Knowledge/
│   │   │   │   ├── KnowledgeEngine.swift       # Knowledge graph engine
│   │   │   │   ├── SemanticSearchService.swift # Semantic search service
│   │   │   │   ├── RelationshipExtractor.swift # Relationship extraction
│   │   │   │   ├── ContextEngine.swift         # Context understanding
│   │   │   │   └── KnowledgeIndexer.swift      # Knowledge indexing
│   │   │   ├── AI/
│   │   │   │   ├── AIAssistant.swift           # AI assistant service
│   │   │   │   ├── SemanticAnalyzer.swift      # Semantic analysis
│   │   │   │   ├── ContentUnderstanding.swift  # Content understanding
│   │   │   │   ├── SmartRecommender.swift      # Smart recommendation
│   │   │   │   └── WritingAssistant.swift      # Writing assistant
│   │   │   ├── Collaboration/
│   │   │   │   ├── CollaborationEngine.swift   # Collaboration engine
│   │   │   │   ├── RealtimeSyncService.swift   # Real-time sync
│   │   │   │   ├── ConflictResolver.swift      # Conflict resolution
│   │   │   │   └── PermissionManager.swift     # Permission manager
│   │   │   └── Infrastructure/
│   │   │       ├── SyncService.swift           # Sync service
│   │   │       ├── APILayer.swift              # API communication layer
│   │   │       ├── ProjectExtractor.swift      # Project extractor
│   │   │       └── PluginManager.swift         # Plugin manager
│   │   ├── Managers/
│   │   │   ├── GraphManager.swift         # Graph structure manager
│   │   │   └── ProjectManager.swift       # Project manager
│   │   └── Utils/
│   │       ├── Extensions.swift           # Common extensions
│   │       ├── Constants.swift            # Constant definitions
│   │       └── Helpers.swift             # Utility functions
│   ├── iOS/                           # iOS-specific code
│   │   ├── Views/
│   │   │   ├── Dashboard/
│   │   │   │   └── DashboardView.swift        # Dashboard main view
│   │   │   ├── Content/
│   │   │   │   ├── ContentLibraryView.swift   # Content library
│   │   │   │   └── ContentDetailView.swift    # Content detail
│   │   │   ├── Favorites/
│   │   │   │   └── FavoritesView.swift        # Favorites view (New)
│   │   │   ├── Tasks/
│   │   │   │   ├── TaskListView.swift         # Task list
│   │   │   │   └── TaskDetailView.swift       # Task detail
│   │   │   ├── Search/
│   │   │   │   └── SearchView.swift           # Search interface
│   │   │   ├── Graph/
│   │   │   │   └── GraphView.swift            # Graph visualization
│   │   │   └── Settings/
│   │   │       └── SettingsView.swift         # Settings interface
│   │   └── Components/
│   │       ├── QuickCaptureView.swift     # Quick capture component
│   │       ├── ContentCardView.swift      # Content card component
│   │       └── SwipeGestureHandler.swift  # Swipe gesture handler
│   ├── macOS/                         # macOS-specific code
│   │   ├── Views/
│   │   │   ├── Sidebar/
│   │   │   │   └── MacSidebarView.swift       # macOS sidebar
│   │   │   ├── Graph/
│   │   │   │   └── MacGraphView.swift         # Graph visualization (desktop)
│   │   │   ├── Menu/
│   │   │   │   └── MacMenuBarView.swift       # Menu bar
│   │   │   └── Export/
│   │   │       └── ProjectExportView.swift    # Project export interface
│   │   ├── Input/
│   │   │   ├── KeyboardShortcuts.swift    # Keyboard shortcuts
│   │   │   └── MouseHandlers.swift        # Mouse operations
│   │   └── Integration/
│   │       ├── ClipboardMonitor.swift     # Clipboard monitoring
│   │       └── FileSystemWatcher.swift    # File system monitoring
│   └── Catalyst/                      # Mac Catalyst adaptation layer
├── tests/                             # Test directory
│   ├── UnitTests/                     # Unit tests
│   ├── IntegrationTests/              # Integration tests
│   └── UITests/                       # UI tests
├── docs/                              # Project documentation
│   ├── ProductStrategy.md             # Product strategy document
│   ├── FeatureSpecification.md        # Feature specification
│   ├── TechnicalRequirements.md       # Technical requirements
│   ├── DesignSystem.md               # Design system guidelines
│   ├── UserExperience.md             # User experience design
│   └── README.md                     # Project README
├── assets/                           # Resource files
│   ├── images/                       # Image resources
│   ├── icons/                        # Icon resources
│   └── localization/                 # Multi-language resources
├── CLAUDE.md                         # This file - Development guide
└── Package.swift                     # Swift Package Manager
```

---

## 🔄 Core Module Implementations / 核心模块实现

### 1. Content Capture Module / 内容捕捉模块

#### ContentCaptureManager Core Functions
```swift
class ContentCaptureManager: ObservableObject {
    // Clipboard monitoring service
    func startClipboardMonitoring()
    func processContent(_ content: CapturedContent) async -> ProcessedContent
    func extractTasks(from content: ProcessedContent) async -> [TaskCandidate]
    
    // Content type detection
    func identifyContentType(_ data: Data) -> ContentType
    func extractTextFromImage(_ image: UIImage) async -> String
    func generateImageDescription(_ image: UIImage) async -> String
}

struct CapturedContent {
    let id: UUID
    let type: ContentType // .text, .image, .mixed
    let rawData: String
    let parsedText: String?
    let timestamp: Date
    let sourceApp: String?
    let metadata: [String: Any]
    let confidence: Double
}
```

### 2. Task Generation Module / 任务生成模块

#### TaskAutoGenerator Intelligence Logic
```swift
class TaskAutoGenerator {
    // Smart task generation from content
    func generateTasks(from content: ContentNode) async -> [TaskCandidate]
    func assessPriority(for task: TaskCandidate) async -> TaskPriority
    func estimateDeadline(for task: TaskCandidate) async -> Date?
    
    // Verb completion mechanism
    func completeActionVerbs(in text: String) -> [ActionItem]
    func extractActionableItems(from text: String) -> [String]
}

struct TaskCandidate {
    let id: UUID
    let title: String
    let description: String?
    let priority: TaskPriority // .high, .medium, .low
    let estimatedDeadline: Date?
    let sourceContentId: UUID
    let confidence: Double
    let actionType: ActionType
}
```

### 3. Knowledge Graph Engine / 知识图谱引擎

#### Advanced Graph Algorithm Implementation
```swift
actor KnowledgeGraphEngine: KnowledgeGraphService {
    private var adjacencyList: [UUID: Set<UUID>] = [:]
    private var nodeStorage: [UUID: KnowledgeNode] = [:]
    private var edgeStorage: [UUID: KnowledgeEdge] = [:]
    private var weightedEdges: [String: Double] = [:]
    
    // Core graph algorithms
    func depthFirstSearch(from startId: UUID, visited: inout Set<UUID>) async -> [UUID]
    func breadthFirstSearch(from startId: UUID) async -> [UUID]
    func topologicalSort() async throws -> [UUID]
    func detectCycles() async -> [[UUID]]
    func shortestPath(from: UUID, to: UUID) async -> PathResult?
    func detectCommunities() async -> [NodeCluster]
    
    // Semantic relationship management
    func extractSemanticRelationships(from content: ContentNode) async -> [SemanticRelation]
    func calculateSemanticSimilarity(between node1: UUID, and node2: UUID) async -> Double
    func clusterRelatedContent() async -> [ContentCluster]
}
```

### 4. Gesture Interaction System / 手势交互系统

#### SwipeGestureHandler Implementation
```swift
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
    
    handleTouchEnd(e) {
        e.stopPropagation();
        const touch = e.changedTouches[0];
        const distX = touch.clientX - this.startX;
        const distY = touch.clientY - this.startY;
        const elapsedTime = new Date().getTime() - this.startTime;
        
        if (elapsedTime <= this.options.allowedTime) {
            if (Math.abs(distX) >= this.options.threshold && Math.abs(distY) <= this.options.restraint) {
                if (distX > 0) {
                    this.onSwipeRight(); // Quick favorite
                } else {
                    this.onSwipeLeft();  // Edit + More buttons
                }
            }
        }
    }
    
    onSwipeLeft() {
        // Show Edit + More buttons
        this.element.classList.add('swiped-left');
        this.showActionButtons();
    }
    
    onSwipeRight() {
        // Quick favorite functionality
        this.element.classList.add('swiped-right');
        this.toggleFavorite();
    }
}
```

---

## 🎯 Target Users & Market Differentiation / 目标用户与市场差异化

### Primary Users (Phase 1) / 主要用户

#### Knowledge Workers & Content Creators / 知识工作者与内容创作者
**User Profile**:
- Researchers, writers, consultants, students
- Handle 50+ information sources daily
- Need efficient capture, organization, and retrieval
- Value data ownership and offline accessibility
- Require intelligent content processing and discovery

**Pain Points**:
- Information scattered across multiple apps
- Manual tagging and organization is time-consuming
- Difficulty finding related concepts across different sources
- No automatic task generation from captured insights

**SnapNotion Solution**:
- Automatic capture of research papers and web articles
- AI-powered semantic tagging and relationship extraction
- Intelligent search across all captured content
- Auto-generated follow-up tasks ("Review Smith et al. methodology")

### Market Differentiation / 市场差异化

| Capability | Evernote | MindMeister | Notion | Obsidian | **SnapNotion Advantage** |
|------------|----------|-------------|--------|----------|-----------------------------|
| **Capture** | 🟢 强大剪藏 | 🟡 手动输入 | 🟡 手动创建 | 🟡 手动编辑 | 🔥 **AI自动捕获+分析** |
| **Organization** | 🟡 文件夹 | 🟢 大纲思维 | 🟢 数据库灵活 | 🟢 双向链接 | 🔥 **三种模式融合** |
| **Search** | 🟢 全文搜索 | 🟡 基础搜索 | 🟡 关键词 | 🟢 图谱导航 | 🔥 **AI语义理解** |
| **Task Integration** | 🔴 无 | 🔴 无 | 🟢 项目管理 | 🟡 插件支持 | 🔥 **自动任务生成** |
| **Data Control** | 🔴 云端 | 🔴 云端 | 🔴 云端 | 🟢 本地优先 | 🔥 **本地+云端双保险** |
| **Collaboration** | 🟡 有限分享 | 🟡 简单协作 | 🟢 实时协作 | 🔴 个人工具 | 🔥 **个人-团队双模式** |

---

## 🎨 Design System & Visual Guidelines / 设计系统与视觉指南

### Brand Identity / 品牌标识

#### Phoenix Branding Theme / 凤凰品牌主题
- **图标**: 橙色凤凰图标 (Phoenix Orange #FF9933)
- **尺寸**: 120px (h-30 w-30)
- **品牌理念**: 象征智能转换与知识重生
- **设计风格**: 简约设计，纯图标，无文字标识

### Color System / 色彩系统

#### Primary Colors / 主要颜色
```swift
// Brand Colors - Phoenix Theme
static let phoenixOrange = Color(red: 1.0, green: 0.6, blue: 0.2)  // #FF9933
static let snapBlue = Color(red: 0.2, green: 0.6, blue: 1.0)       // #3399FF
static let snapGreen = Color(red: 0.2, green: 0.8, blue: 0.4)      // #33CC66
static let snapPurple = Color(red: 0.6, green: 0.2, blue: 1.0)     // #9933FF

// Semantic Colors
static let successColor = Color.green
static let warningColor = phoenixOrange
static let errorColor = Color.red
static let infoColor = snapBlue
```

#### Tab Navigation Color System / Tab导航配色系统
1. **Dashboard**: 蓝色分析主题 (仪表板图标 + 蓝色分析背景)
2. **Library**: 绿色图书主题 (书本图标 + 绿色图书背景)
3. **Favorites**: 红色/粉色收藏主题 (心形图标 + 红色/粉色收藏背景) **[NEW]**
4. **Tasks**: 橙色清单主题 (清单图标 + 橙色任务背景)
5. **Graph**: 紫色网络主题 (网络图标 + 紫色关系背景)

### Typography / 字体排印

#### Font Hierarchy / 字体层级
```swift
// Display Fonts
.largeTitle     // 34pt - Page headers
.title          // 28pt - Section headers  
.title2         // 22pt - Subsection headers
.title3         // 20pt - Content headers

// Body Fonts
.headline       // 17pt semibold - Article headlines
.body           // 17pt regular - Primary text
.callout        // 16pt regular - Secondary text
.subheadline    // 15pt regular - Metadata
.footnote       // 13pt regular - Captions
.caption        // 12pt regular - Fine print
```

#### Chinese Typography / 中文字体排印
- **Primary**: PingFang SC (Simplified Chinese)
- **Fallback**: Helvetica Neue (Latin characters)
- **Reading**: Increased line spacing for Chinese text (1.4x)

### Component Design Standards / 组件设计标准

#### Content Card Design / 内容卡片设计
每个内容卡片包含统一的视觉元素：
- **图标区域**: 左侧内容类型图标
- **标题区域**: 主要内容描述
- **元信息区域**: 来源、时间戳、置信度
- **标签区域**: 智能标签和数量指示
- **操作区域**: 收藏状态和交互按钮

```swift
struct ContentCard: View {
    var content: ContentNode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                content.typeIcon
                Text(content.title)
                    .font(.headline)
                Spacer()
                Text(content.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(content.preview)
                .font(.body)
                .lineLimit(3)
            
            if !content.tags.isEmpty {
                TagRow(tags: content.tags)
            }
            
            // AI Confidence and Source Info
            HStack {
                if let confidence = content.aiConfidence {
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let source = content.source {
                    Text("from \(source)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
```

---

## ✅ Success Metrics & Quality Assurance / 成功指标与质量保证

### User Engagement Metrics / 用户参与度指标
- Daily active content captures per user (target: 10+)
- Knowledge retrieval success rate (target: 85%+)
- Task completion rate from auto-generated tasks (target: 70%+)

### Product Performance Metrics / 产品性能指标
- Content processing speed (target: <2s for most formats)
- Search result relevance score (target: 90%+)
- Cross-platform sync accuracy (target: 99.9%+)

### Business Goals / 商业目标
- User retention rate at 30 days (target: 60%+)
- Conversion from individual to team plans (target: 15%+)
- Net Promoter Score (target: 50+)

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

## 🚀 Development Guidelines & Best Practices / 开发指南与最佳实践

### Architecture Principles / 架构设计原则
- **Shared Code Maximization**: Shared module contains 80%+ business logic
- **Platform-Specific Adaptation**: Each platform maintains native experience
- **Responsive Design**: Single codebase adapts to different screen sizes
- **Conditional Compilation**: Use `#if os()` for platform differentiation

### Multi-Platform Design Standards / 多平台设计规范
- **iPhone**: Thumb Zone design, core buttons within thumb reach
- **iPad**: Split View support, drag-and-drop operations
- **macOS**: Menu bar integration, keyboard shortcuts

### API Interface Standards / API接口规范  
- **RESTful Style**: Unified JSON format
- **Version Control**: `/api/v1/` path specification
- **Error Handling**: Standard error code definitions
- **Authentication**: Bearer Token method

### Development Checklist / 开发检查清单

#### Feature Development Checklist
- [ ] Have you reviewed the relevant documentation files for specific requirements?
- [ ] Have you considered multi-platform compatibility?
- [ ] Have you used the Shared module for code reuse?
- [ ] Have you followed the design standards for the corresponding platform?
- [ ] **🌐 Have you implemented multi-language support?**
- [ ] **🌐 Have all user-visible texts been localized?**

#### Technical Standards Checklist
- [ ] Does it comply with API interface standards?
- [ ] Have you implemented error handling and fallback design?
- [ ] Have you tested cross-platform functionality consistency?
- [ ] Have you updated development task status?

#### Code Quality Checklist
- [ ] Have you written unit tests?
- [ ] Have you conducted code reviews?
- [ ] Does it follow Swift coding standards?
- [ ] Have you optimized performance and memory usage?

---

## 📚 Essential Documentation Reference / 核心文档参考

**During development, please refer to the following documentation files:**

### Must-Read Documents (Located in `/docs/` directory)
1. **`ProductStrategy.md`** - Complete product strategy and market positioning
2. **`FeatureSpecification.md`** - Detailed feature requirements and priorities  
3. **`TechnicalRequirements.md`** - Technical architecture, performance, security
4. **`DesignSystem.md`** - ⭐ **Three-panel interface design standards** - Core UI/UX architecture
5. **`UserExperience.md`** - User scenarios, interaction flows, UX principles

### Documentation Usage Guide
- **When requirements change**: Check `ProductStrategy.md` for scope confirmation
- **During technical implementation**: Reference `TechnicalRequirements.md` architecture design
- **During UI development**: Must comply with `DesignSystem.md` interaction standards
- **For user experience**: Follow `UserExperience.md` user journey guidelines

---

## 🔄 Next Development Priorities / 下一步开发重点

### P0 Priority (Core MVP)
1. **Foundation Architecture**
   - Complete project framework setup
   - Establish multi-platform code structure
   - Implement basic data models

2. **Content Capture Core Features**
   - Clipboard monitoring service
   - Basic content recognition
   - Local storage implementation

### P1 Priority (Enhanced Features)  
1. **AI Intelligent Processing**
   - OCR text recognition
   - Automatic task generation
   - Smart tagging system

2. **User Interface Development**
   - iOS core interface
   - macOS interface adaptation
   - Cross-platform component library

### Development Timeline Suggestion
- **Month 1**: Foundation architecture + Content capture
- **Month 2**: AI service integration + Task system
- **Month 3**: UI completion + Search functionality
- **Month 4**: Knowledge graph + Advanced features

---

**Important Reminders**: 
1. **🌐 Multi-language support is a required feature** - every new feature must support both Chinese and English
2. **Prioritize Shared module completion during multi-platform development** to ensure business logic reuse
3. **Documentation is an important development reference** - each feature should strictly follow corresponding document requirements
4. **Consider internationalization from project start** rather than adding it later
5. **Maintain clean code and clear architecture** to establish a good foundation for future expansion

---

**Project Name**: SnapNotion  
**Version**: v1.0.0  
**Last Updated**: 2025-08-22  
**Maintenance Team**: SnapNotion Development Team