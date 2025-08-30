# SnapNotion Design System
## 设计系统规范文档

---

## 1. UI Design Principles / UI设计原则

### Core Design Philosophy / 核心设计理念

#### 1.1 Knowledge-First Interface / 知识优先界面
- **Content is King**: Interface elements should never overshadow the content
- **Cognitive Load Minimization**: Reduce visual noise to enhance focus
- **Semantic Clarity**: Every UI element should have clear purpose and meaning

#### 1.2 Native Platform Excellence / 原生平台卓越性
- **Platform Consistency**: Follow Apple Human Interface Guidelines
- **Adaptive Design**: Single codebase, platform-optimized experience
- **Gesture Fluidity**: Natural, intuitive touch and pointer interactions

#### 1.3 Intelligence Transparency / 智能透明性
- **AI as Assistant**: AI features should feel helpful, not intrusive
- **User Control**: Always provide manual override options
- **Progressive Disclosure**: Advanced features appear when needed

### Three-Panel Architecture Design / 三面板架构设计

#### Core Navigation Structure / 核心导航结构

```
┌─────────────────────────────────────────────────────────┐
│  Left Panel     │    Main Panel    │   Right Panel     │
│  (Settings)     │   (Core App)     │  (Advanced)       │
│                 │                  │                   │
│  ├─ Profile     │  ┌─────────────┐ │  ├─ Knowledge     │
│  ├─ Sync        │  │ Dashboard   │ │  │   Graph        │
│  ├─ AI Config   │  │ Library     │ │  ├─ AI Tools     │
│  ├─ Export      │  │ Tasks       │ │  ├─ Analytics    │
│  └─ About       │  │ Search      │ │  └─ Plugins      │
│                 │  └─────────────┘ │                   │
└─────────────────────────────────────────────────────────┘
```

#### Panel Specifications / 面板规格

##### Left Panel (Settings & Configuration) / 左面板
- **Width**: 280pt (iOS), 320pt (macOS)
- **Trigger**: Swipe from left edge / Menu button
- **Content**: User settings, sync status, AI configuration
- **Animation**: Slide-in with backdrop blur

###### Left Panel Detailed Design / 左面板详细设计

**Panel Header / 面板标题区域**
- **主标题**: "Settings & Configuration"
- **副标题**: "Customize your SnapNotion experience"
- **设置图标**: 齿轮图标，灰色背景圆形容器

**Content Capture Settings Group / Content Capture 设置组**
📁 **Content Capture** (蓝色文件夹图标)
- **Auto-capture clipboard** (蓝色剪贴板图标) - 开启状态
- **OCR for images** (绿色相机图标) - 开启状态
- **Monitor web browsing** (紫色网络图标) - 关闭状态
- **Audio transcription** (橙色麦克风图标) - 关闭状态

**AI Processing Settings Group / AI Processing 设置组**
🤖 **AI Processing** (紫色AI图标)
- **Auto-generate tasks** (蓝色任务图标) - 开启状态
- **Smart tagging** (绿色标签图标) - 开启状态
- **Content summarization** (紫色文档图标) - 开启状态

**AI Model Selection / AI Model 选择**
- **GPT-4** (黑色选中状态)
- **Claude** (白色未选中)
- **Local** (白色未选中)

**Privacy & Security Settings Group / Privacy & Security 设置组**
🔒 **Privacy & Security** (绿色盾牌图标)
- **End-to-end encryption** (绿色锁图标) - 开启状态
- **Local-first processing** (蓝色服务器图标) - 开启状态
- **Anonymous analytics** (灰色图表图标) - 关闭状态
- **Export All Data** (下载图标) - 白色按钮

**System Status Area / System Status 状态区域**
🟢 **System Status** (绿色状态点)
- **Local Processing**: Active (绿色状态)
- **Encryption**: Enabled (绿色状态)

##### Main Panel (Core Application) / 主面板
- **Layout**: Tab-based navigation (5 main tabs) - Updated to include Favorites
- **Tabs**: Dashboard, Library, Favorites, Tasks, Graph
- **Persistence**: Always visible, primary interaction space

##### Right Panel (Advanced Features) / 右面板
- **Width**: 320pt (iOS), 400pt (macOS)
- **Trigger**: Swipe from right edge / Advanced button
- **Content**: Knowledge graph, AI tools, analytics
- **Progressive**: Shows contextual advanced options

###### Right Panel Strategy / 右面板设计策略

**Primary Functions / 主要功能定位**
- **数据分析与洞察**: 内容使用统计、趋势分析、效率指标
- **批量操作工具**: 多选操作、批量编辑、批量导出
- **高级搜索功能**: 语义搜索、复杂筛选、关系图谱
- **开发者工具**: API 集成、自动化脚本、数据导出格式
- **内容管理**: 重复内容检测、智能分类建议、存储优化

**Alternative: Account & Billing Module / 备选方案：账户管理模块**
(可作为独立功能或网页版实现)
- **Current Plan**: Free Plan $0/forever
- **Usage Metrics**: Content Captures, AI Processing, Storage with progress bars
- **Upgrade to Pro**: 蓝紫色渐变按钮
- **Account Management**: Profile, Notifications, Payment Methods, Advanced Settings

---

## 2. Figma Design Files / Figma设计文件

### Design File Structure / 设计文件结构

#### Main Design System File
**File Name**: `SnapNotion-Design-System-v1.0.fig`
**Link**: [Design System Components](https://figma.com/snapnotion-design-system)

**Contents**:
- Color palette and semantic colors
- Typography system with Chinese/English fonts
- Component library (buttons, cards, inputs)
- Icon library with SF Symbols integration
- Layout grids and spacing systems

#### Platform-Specific Design Files

##### iOS/iPadOS Design File
**File Name**: `SnapNotion-iOS-Screens-v1.0.fig`
**Link**: [iOS App Screens](https://figma.com/snapnotion-ios)

**Contents**:
- iPhone screens (12, 13, 14, 15 Pro Max)
- iPad screens (Air, Pro 11", Pro 12.9")
- Responsive breakpoints and adaptations
- Touch interaction specifications
- Accessibility annotations

##### macOS Design File
**File Name**: `SnapNotion-macOS-Interface-v1.0.fig`
**Link**: [macOS App Interface](https://figma.com/snapnotion-macos)

**Contents**:
- Desktop interface layouts
- Menu bar and context menu designs
- Multiple window configurations
- Keyboard shortcut overlays
- Mouse/trackpad interaction specs

#### Interactive Prototypes

##### User Flow Prototypes
**File Name**: `SnapNotion-User-Flows-v1.0.fig`
**Link**: [Interactive Prototypes](https://figma.com/snapnotion-flows)

**Contents**:
- Onboarding flow (3-step setup)
- Content capture flow (automatic & manual)
- Search and discovery flow
- Task generation and management flow
- Knowledge graph exploration flow

---

## 3. Visual Style Guide / 视觉风格指南

### 🎨 Brand Identity / 品牌标识

#### Logo Design / Logo 设计
- **图标**: 橙色凤凰图标
- **尺寸**: 120px (h-30 w-30)
- **品牌理念**: 象征智能与转换能力
- **设计风格**: 简约设计，纯图标，无文字标识

### Color Palette / 调色板

#### Primary Colors / 主要颜色
```swift
// Brand Colors - Updated Phoenix Theme
static let phoenixOrange = Color(red: 1.0, green: 0.6, blue: 0.2)  // #FF9933 - Primary Brand
static let snapBlue = Color(red: 0.2, green: 0.6, blue: 1.0)       // #3399FF
static let snapGreen = Color(red: 0.2, green: 0.8, blue: 0.4)      // #33CC66
static let snapPurple = Color(red: 0.6, green: 0.2, blue: 1.0)     // #9933FF

// Semantic Colors
static let successColor = Color.green
static let warningColor = phoenixOrange
static let errorColor = Color.red
static let infoColor = snapBlue
```

#### Tab Navigation Color System / Tab 导航配色系统
1. **Dashboard**: 蓝色分析主题
   - 背景图像：蓝色分析背景
   - 图标：仪表板图标
   
2. **Library**: 绿色图书主题
   - 背景图像：绿色图书背景
   - 图标：书本图标
   
3. **Favorites**: 红色/粉色收藏主题 (New Tab)
   - 背景图像：红色/粉色收藏背景
   - 图标：心形图标
   
4. **Tasks**: 橙色清单主题
   - 背景图像：橙色任务背景
   - 图标：清单图标
   
5. **Graph**: 紫色网络主题
   - 背景图像：紫色关系背景
   - 图标：网络图标

#### Quick Capture Color Scheme / 快速捕获配色方案
1. **Text (蓝色)**: 文档图标，用于快速文本记录
2. **Photo (绿色)**: 相机图标，用于拍照捕获  
3. **Screen (紫色)**: 手机图标，用于截屏捕获

#### Settings Panel Icon Colors / 设置面板图标配色
- **Content Capture**: 蓝色文件夹图标
- **AI Processing**: 紫色AI图标
- **Privacy & Security**: 绿色盾牌图标
- **System Status**: 绿色状态点

##### Functional Icon Color Details / 功能图标详细配色
1. **Content Capture 组**:
   - Auto-capture clipboard: 蓝色剪贴板图标
   - OCR for images: 绿色相机图标
   - Monitor web browsing: 紫色网络图标
   - Audio transcription: 橙色麦克风图标

2. **AI Processing 组**:
   - Auto-generate tasks: 蓝色任务图标
   - Smart tagging: 绿色标签图标
   - Content summarization: 紫色文档图标

3. **Privacy & Security 组**:
   - End-to-end encryption: 绿色锁图标
   - Local-first processing: 蓝色服务器图标
   - Anonymous analytics: 灰色图表图标

#### Status Color System / 状态颜色系统
- **成功状态**: 绿色 (Local Processing: Active, Encryption: Enabled)
- **警告状态**: 橙色/黄色
- **错误状态**: 红色
- **中性状态**: 灰色
- **信息状态**: 蓝色

#### Adaptive Colors / 自适应颜色
- **Primary Text**: Label (Dynamic)
- **Secondary Text**: SecondaryLabel (Dynamic)
- **Background**: SystemBackground (Dynamic)
- **Surface**: SecondarySystemBackground (Dynamic)

#### Color Usage Guidelines / 颜色使用指南
- **Phoenix Orange**: Primary brand identity, key highlights
- **Snap Blue**: Primary actions, links, active states
- **Snap Green**: Success states, completed tasks, positive feedback
- **Snap Purple**: Advanced features, AI processing indicators
- **System Colors**: Follow platform conventions for consistency

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

#### Typography Rules / 字体规则
- **Line Height**: 1.3x for English, 1.4x for Chinese
- **Paragraph Spacing**: 16pt between paragraphs
- **Character Spacing**: Default system spacing
- **Dynamic Type**: Full support for user accessibility preferences

### Spacing & Layout / 间距与布局

#### Grid System / 网格系统
- **Base Unit**: 8pt grid system
- **Margins**: 16pt (iPhone), 20pt (iPad), 24pt (macOS)
- **Component Spacing**: 8pt, 16pt, 24pt, 32pt
- **Safe Areas**: Full support for all devices

#### Component Sizing / 组件尺寸
- **Touch Targets**: Minimum 44pt × 44pt
- **Buttons**: Height 44pt (iOS), 32pt (macOS)
- **Text Fields**: Height 44pt with 8pt padding
- **Cards**: Corner radius 12pt, shadow 2pt

### Iconography / 图标系统

#### Icon Style / 图标风格
- **Primary**: SF Symbols from Apple
- **Style**: Medium weight, rounded corners
- **Size**: 16pt, 20pt, 24pt, 32pt standard sizes
- **Rendering**: Template images with semantic colors

#### Content Type Icons / 内容类型图标
- **文本内容**: `doc.text` - 蓝色文档图标
- **截图内容**: `camera` - 相机相关图标
- **图片内容**: `photo` - 图片相关图标
- **PDF文档**: `doc.richtext`
- **网页内容**: `globe`
- **语音内容**: `mic`
- **混合内容**: `doc.append`

#### Functional Operation Icons / 功能操作图标
- **搜索**: `magnifyingglass` - 放大镜图标
- **设置**: `gear` - 齿轮图标
- **收藏**: `heart` - 心形图标
- **编辑**: `pencil` - 编辑图标
- **更多**: `ellipsis` - 更多操作图标

#### Status Indicator Icons / 状态指示图标
- **任务状态**:
  - 待办: `circle` - 灰色
  - 进行中: `circle.fill` - 蓝色  
  - 等待中: `clock` - 橙色
  - 已完成: `checkmark.circle.fill` - 绿色
  - 已取消: `xmark.circle` - 红色

#### Custom Icons / 自定义图标
- **Knowledge Graph**: Custom network visualization icons
- **Content Types**: Specialized icons for different content formats
- **AI Features**: Distinctive icons for AI-powered functions
- **Actions**: Clear, intuitive action iconography

---

## 4. Platform-Specific Adaptations / 平台特定适配

### iPhone Design Principles / iPhone设计原则

#### Thumb Zone Optimization / 拇指区域优化
```
┌─────────────────┐
│     [Safe]      │ ← Status bar area
│                 │
│   [Comfort]     │ ← Easy reach zone
│                 │
│    [Stretch]    │ ← Requires hand adjustment
│                 │
│ [Action Zone]   │ ← Primary buttons here
└─────────────────┘
```

- **Primary Actions**: Bottom 44pt of screen
- **Navigation**: Top navigation + bottom tab bar
- **Content**: Center area for reading/browsing

#### iPhone Specific Features / iPhone特定功能
- **Quick Capture**: Bottom-right floating action button
- **Voice Input**: Long-press microphone icon
- **Shake to Undo**: Hardware gesture support

### iPad Design Principles / iPad设计原则

#### Split View Excellence / 分屏视图卓越性
- **Adaptive Layout**: Sidebar + detail view
- **Drag & Drop**: Full support for content organization
- **Multi-touch**: Two-finger gestures for navigation
- **Apple Pencil**: Precise annotation and drawing

#### iPad Specific Features / iPad特定功能
- **Slide Over**: Quick capture panel
- **Picture in Picture**: Video content support
- **Keyboard Shortcuts**: External keyboard support

### macOS Design Principles / macOS设计原则

#### Desktop-Class Interface / 桌面级界面
- **Menu Bar Integration**: Native macOS menu structure
- **Window Management**: Multiple windows, full-screen mode
- **Keyboard First**: Comprehensive shortcut support
- **Right-Click Context**: Contextual menus throughout

#### macOS Specific Features / macOS特定功能
- **Touch Bar**: Dynamic function keys (Legacy support)
- **Spotlight Integration**: System-wide search
- **Services**: Text processing and workflow integration

---

## 5. Component Design Standards / 组件设计标准

### Navigation Components / 导航组件

#### Tab Bar (Main Navigation) / 标签栏
```swift
TabView {
    DashboardView()
        .tabItem { Label("Dashboard", systemImage: "house") }
    
    LibraryView()
        .tabItem { Label("Library", systemImage: "books.vertical") }
    
    TasksView()
        .tabItem { Label("Tasks", systemImage: "checkmark.circle") }
    
    GraphView()
        .tabItem { Label("Graph", systemImage: "point.3.connected.trianglepath.dotted") }
}
```

#### Navigation Bar / 导航栏
- **Title**: Current context (Dashboard, Content, etc.)
- **Leading**: Panel toggle / Back button
- **Trailing**: Search, Add, Profile buttons

### Content Components / 内容组件

#### Content Card Design Standards / 内容卡片设计规范

每个内容卡片包含统一的视觉元素：
- **图标区域**: 左侧内容类型图标
- **标题区域**: 主要内容描述
- **元信息区域**: 来源、时间戳、置信度
- **标签区域**: 智能标签和数量指示
- **操作区域**: 收藏状态和交互按钮

##### Content Card Examples / 内容卡片示例

###### 📝 文本内容示例
- **图标**: 蓝色文档图标
- **标题**: "Design team meeting scheduled for mobile interface discussion"
- **来源**: "from Messages"
- **类型标识**: "Text"
- **时间戳**: "46m ago"
- **置信度**: "95%" AI分析置信度
- **标签**: "meeting", "design" + 更多标签数量 "+2"

###### 📱 截图内容示例
- **缩略图**: iPhone设置界面预览图
- **标题**: "iPhone settings screenshot: Focus mode configuration for notifications"
- **来源**: "from Screenshots"
- **类型标识**: "Screenshot"
- **时间戳**: "1h ago"
- **置信度**: "88%"
- **标签**: "settings", "focus-mode" + "+2"

###### 📷 图片内容示例
- **缩略图**: 项目时间线白板照片预览
- **标题**: "Project timeline whiteboard: Q1 2024 milestones and deadlines"
- **来源**: "from Camera"
- **类型标识**: "Image"
- **时间戳**: "2h ago"
- **置信度**: "92%"
- **标签**: "project", "timeline" + "+3"

##### Card State Management / 卡片状态管理
- **默认状态**: 正常显示状态
- **悬停状态**: 鼠标悬停时的视觉反馈
- **选中状态**: 多选操作时的选中显示
- **滑动状态**: 左右滑动时露出的操作按钮

#### Content Cards / 内容卡片代码实现
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

#### Task Items / 任务项目
```swift
struct TaskItem: View {
    @Binding var task: TaskNode
    
    var body: some View {
        HStack {
            Button {
                task.toggleComplete()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            PriorityBadge(priority: task.priority)
        }
        .padding(.vertical, 4)
    }
}
```

### Input Components / 输入组件

#### Search Bar / 搜索栏

##### Search Functionality Area / 搜索功能区域
- **搜索框**: "Search captures..." 占位符文本
- **搜索图标**: 左侧放大镜图标
- **全宽设计**: 搜索框占据页面全宽，圆角背景
- **实时搜索**: 支持内容、标签、来源的实时搜索过滤

##### Content Management Area / 内容管理区域
- **页面标题**: "Captures" + 项目数量显示 "7 items"
- **视图切换**: 四种视图模式选择
  1. **列表视图** (当前选中)
  2. **网格视图**
  3. **卡片视图**
  4. **紧凑视图**
- **排序选项**: 支持按时间、类型、来源等排序

##### Advanced Search Features / 高级搜索功能
- **Scope**: All content types with filters
- **Suggestions**: Real-time as-you-type results
- **Voice**: Microphone button for voice search
- **Semantic Search**: AI-powered content understanding

#### Quick Capture / 快速捕获

##### Three Capture Modes / 三种捕获方式
1. **Text (蓝色)**: 文档图标，用于快速文本记录
2. **Photo (绿色)**: 相机图标，用于拍照捕获
3. **Screen (紫色)**: 手机图标，用于截屏捕获

##### Design Specifications / 设计规范
- **圆角按钮**: 大型触摸友好的圆形按钮设计
- **滑动提示**: "Swipe to see more options" 提示更多捕获选项
- **AI Enhancement**: Automatic processing and tagging

#### Today's Focus Area / Today's Focus 区域

##### Task Reminders / 任务提醒
- **状态指示**: "1 task need attention" 数量提示
- **具体任务**: 展示具体任务内容和时间
- **任务标题**: "Call Sarah at 3 PM for dashboard feedback"
- **优先级标签**: "medium" 中等优先级
- **截止时间**: "Due 8/22/2025"

#### Recent Captures Area / Recent Captures 区域

##### Latest Content Display / 最新内容显示
- **标题**: "Latest content from your workflow"

##### Content Card Variations / 内容卡片变化
1. **会议文本**:
   - 铅笔图标 + "Design team meeting scheduled for mobile interface discussion"
   - 来源标识: "from Messages"
   - 时间标识: "39m ago"
   - 标签系统: "text", "meeting", "design"
   - 收藏状态: 红色心形图标

2. **截图内容**:
   - 截图预览缩略图 + "iPhone settings screenshot: Focus mode configuration for notifications"
   - 来源标识: "from Screenshots"
   - 时间标识: "1h ago"
   - 标签系统: "screenshot", "settings", "focus-mode"

3. **项目内容**:
   - 白板图片预览 + "Project timeline whiteboard: Q1 2024 milestones and deadlines"

### Animation & Transitions / 动画与过渡

#### Animation Principles / 动画原则
1. **Purposeful**: Every animation should have clear intent
2. **Natural**: Follow real-world physics and timing
3. **Responsive**: Immediate feedback for user actions
4. **Accessible**: Respect motion sensitivity preferences

#### Standard Animations / 标准动画

##### Panel Transitions / 面板过渡
```swift
// Slide-in from sides
.transition(.asymmetric(
    insertion: .move(edge: .leading),
    removal: .move(edge: .leading)
))

// Duration: 0.3 seconds
// Easing: easeInOut
```

##### Content Transitions / 内容过渡
```swift
// Card appearance
.transition(.scale.combined(with: .opacity))

// List item insertion
.transition(.move(edge: .top).combined(with: .opacity))
```

#### Loading States / 加载状态
- **Skeleton Screens**: Content-shaped placeholders
- **Progress Indicators**: Determinate when possible
- **Micro-interactions**: Button press feedback

---

## 6. Accessibility Guidelines / 无障碍指南

### Core Accessibility Features / 核心无障碍功能

#### VoiceOver Support / VoiceOver支持
- **Labels**: Descriptive, not verbose
- **Hints**: Action explanations when needed
- **Traits**: Proper semantic roles
- **Grouping**: Logical content organization

#### Dynamic Type Support / 动态字体支持
```swift
Text("Content Title")
    .font(.headline)
    .lineLimit(nil)  // Allow text to wrap
    .minimumScaleFactor(0.8)  // Prevent excessive scaling
```

#### Color & Contrast / 颜色与对比度
- **Minimum Contrast**: 4.5:1 for normal text
- **Enhanced Contrast**: 7:1 for important content
- **Color Independence**: Never rely solely on color
- **Pattern Support**: Visual patterns + color coding

#### Motor Accessibility / 运动无障碍
- **Touch Targets**: Minimum 44pt × 44pt
- **Gesture Alternatives**: Button alternatives for swipes
- **Timeout Extensions**: Generous interaction timeouts
- **Voice Control**: Full voice navigation support

### Internationalization Design / 国际化设计

#### Multi-language Support / 多语言支持

##### Text Expansion / 文本扩展
- **German**: +35% text length allowance
- **Chinese**: Vertical text support (optional)
- **Arabic**: Right-to-left layout support (future)
- **Dynamic Sizing**: Flexible layouts for all languages

##### Cultural Adaptations / 文化适配
- **Date Formats**: Locale-specific formatting
- **Number Formats**: Regional decimal separators
- **Color Meanings**: Cultural color associations
- **Icon Choices**: Universally understood symbols

---

## 7. Design Review Checklist / 设计审查清单

### Visual Design Review / 视觉设计审查
- [ ] Follows Apple Human Interface Guidelines
- [ ] Consistent with SnapNotion design system
- [ ] Proper color contrast ratios
- [ ] Typography hierarchy maintained
- [ ] Spacing follows 8pt grid system

### Interaction Design Review / 交互设计审查  
- [ ] Touch targets meet minimum size requirements
- [ ] Gestures are intuitive and learnable
- [ ] Feedback provided for all user actions
- [ ] Navigation paths are clear and logical
- [ ] Error states are handled gracefully

### Accessibility Review / 无障碍审查
- [ ] VoiceOver labels are descriptive
- [ ] Dynamic Type scaling works properly
- [ ] Color is not the only information indicator
- [ ] Focus management works correctly
- [ ] Motion sensitivity preferences respected

### Platform Review / 平台审查
- [ ] iPhone: Thumb-friendly navigation
- [ ] iPad: Utilizes large screen effectively
- [ ] macOS: Keyboard shortcuts implemented
- [ ] Catalyst: Optimized for desktop interaction
- [ ] Cross-platform consistency maintained

### Interaction Design Standards / 交互设计标准

#### Settings Panel Interaction Specs / 设置面板交互规范

##### Component Types / 组件类型
- **Toggle Switches**: iOS风格的toggle开关，开启为黑色，关闭为灰色
- **Button Groups**: AI Model使用黑色选中/白色未选中的按钮组
- **Grouping Layout**: 清晰的功能分组，每组有独立的圆角容器
- **Icon System**: 每个功能配有彩色图标，便于识别
- **Status Feedback**: 实时显示系统状态和功能启用情况
- **Scroll Support**: 长内容支持垂直滚动浏览

#### Navigation System Design / 导航系统设计

##### Bottom Tab Navigation / 底部 Tab 导航
- **Native iOS Style**: 原生 iOS 风格，位于屏幕底部
- **Tab Count**: 5 tabs (Dashboard, Library, Favorites, Tasks, Graph)

##### Gesture Navigation / 手势滑动
- **Three-Panel Switching**: 三面板间的触摸手势切换
- **Swipe Interactions**: Left/Right swipe for panel navigation

##### Alternative Navigation / 替代导航
- **Hamburger Menu**: 汉堡菜单按钮用于非手势导航
- **Arrow Buttons**: 箭头按钮用于面板切换

#### Development Implementation Guidelines / 开发实施要点

##### Critical Design Principles / 必须遵循的设计原则
1. **Layout Structure Integrity**: 布局结构绝对不能改动 (位置、尺寸、间距、组件排列)
2. **Visual Optimization Only**: 允许视觉优化但保持布局不变
3. **Figma Strict Compliance**: 严格按照 Figma 设计实现基础布局
4. **Platform Optimization**: 在保持布局基础上进行 iOS 平台优化

##### Technical Implementation Priority / 技术实施优先级
1. **Three-Panel Layout & Gesture System**: 三面板布局与手势系统
2. **Five-Tab Navigation**: 底部5个 Tab 导航实现 (新增 Favorites)
3. **Favorites & Swipe Interaction**: 收藏功能与右滑快速收藏交互
4. **AI Processing Visualization**: AI 处理可视化功能
5. **Responsive Adaptation**: 响应式适配与设备优化
6. **Performance & Animation**: 性能优化与动画完善

#### Data Visualization Standards / 数据可视化标准

##### Progress Indicators / 进度指示器
- **Usage Metrics**: Content Captures, AI Processing, Storage 的进度条显示
- **AI Processing Progress**: "AI Generated" 按钮下方的小型进度指示器
- **Color Coding**: 不同类型进度使用不同颜色区分

##### Status Indicators / 状态指示器
- **Dot Status**: 绿色、橙色、红色等状态点
- **Icon Status**: 配合图标的状态显示
- **Text Status**: 明确的状态描述文字

#### Dark Mode Support / 深色模式支持

##### Color Adaptation / 色彩适配
- **Background Colors**: 深色模式下的背景色调整
- **Text Colors**: 确保在深色背景下的可读性
- **Icon Colors**: 深色模式下的图标颜色适配
- **Brand Colors**: 保持品牌色在深色模式下的识别度

##### Automatic Switching / 自动切换
- **System Integration**: 跟随系统深色模式设置
- **Manual Toggle**: 提供用户手动切换选项
- **Preference Memory**: 记住用户的偏好设置

---

*Last Updated: 2025-08-22*  
*Version: 1.0.0*  
*Next Review: Pre-Development Design Freeze*  
*Includes: Figma UI Specifications Integration*