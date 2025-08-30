# Contributing to SnapNotion

Thank you for your interest in contributing to SnapNotion! This document provides guidelines and information for contributors.

## 🎯 **Project Overview**

SnapNotion is an AI-powered universal content capture app for iOS that transforms any content into organized, searchable knowledge. We follow Apple's design principles and modern iOS development practices.

## 🚀 **Getting Started**

### Prerequisites
- iOS 16.0+ / macOS 13.0+
- Xcode 15.0+
- Swift 5.9+
- Apple Developer Account (for device testing)

### Development Environment Setup
1. Fork and clone the repository
2. Open `SnapNotion/SnapNotion.xcodeproj` in Xcode
3. Configure your development team and bundle identifiers
4. Build and run on simulator or device

## 🏗️ **Project Architecture**

### Code Organization
```
SnapNotion/
├── 🎨 Views/              # SwiftUI interface components
├── 🧠 ViewModels/         # Business logic & data flow
├── 🔧 Services/           # Core functionality services
├── 📊 Models/             # Data structures & Core Data
├── 🎨 Typography/         # Claude Code typography system
├── 🔗 ShareExtension/     # Share extension target
└── 📚 Resources/          # Assets, localization files
```

### Key Principles
- **SwiftUI-first**: Modern declarative UI development
- **MVVM Pattern**: Clean separation of concerns
- **Protocol-oriented**: Testable and maintainable code
- **Performance-focused**: Smooth 60fps experience
- **Privacy-first**: On-device processing when possible

## 📝 **Code Standards**

### Swift Style Guide
We follow [Apple's Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these additions:

**Naming Conventions:**
```swift
// ✅ Good
class ContentViewModel: ObservableObject {
    @Published var items: [ContentItem] = []
    private let contentService: ContentServiceProtocol
}

// ❌ Avoid
class ContentVM: ObservableObject {
    var data: [Any] = []
    var svc: ContentService
}
```

**Error Handling:**
```swift
// ✅ Good - Graceful error handling
func processContent() async {
    do {
        let result = try await aiProcessor.analyze(content)
        await updateUI(with: result)
    } catch {
        logger.error("Content processing failed: \(error)")
        await showErrorMessage(error.localizedDescription)
    }
}

// ❌ Avoid - Force unwrapping or fatalError in production
func processContent() {
    let result = try! aiProcessor.analyze(content)  // Crashes app
    fatalError("Processing failed")  // Never acceptable
}
```

### SwiftUI Best Practices
- Use `@StateObject` for view model ownership
- Prefer `@ObservedObject` for injected dependencies
- Extract complex views into separate components
- Use proper accessibility modifiers

### Documentation
- Document public APIs with Swift DocC format
- Include code examples for complex functionality
- Update README.md for significant changes

## 🧪 **Testing Requirements**

### Unit Tests
- **Target Coverage**: >90% for core business logic
- **Test Location**: `SnapNotionTests/`
- **Naming**: `ClassNameTests.swift`

```swift
final class ContentServiceTests: XCTestCase {
    func testContentProcessing_withValidImage_returnsProcessedContent() async throws {
        // Given
        let service = ContentService(aiProcessor: MockAIProcessor())
        let testImage = UIImage(systemName: "photo")!
        
        // When
        let result = try await service.processImage(testImage)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result.type, .image)
    }
}
```

### Integration Tests
- Test share extension communication
- Validate Core Data + CloudKit sync
- Verify AI processing pipeline

### UI Tests
- Test critical user flows (capture, search, sync)
- Ensure accessibility compliance
- Validate performance on device

## 🔍 **Quality Assurance**

### Before Submitting
- [ ] All tests pass (`⌘+U` in Xcode)
- [ ] No compiler warnings
- [ ] Code formatted with SwiftFormat
- [ ] Performance tested on device
- [ ] Accessibility verified with VoiceOver

### Performance Standards
- App launch time: <3 seconds cold start
- Content processing: <2 seconds per item
- Memory usage: <150MB peak usage
- Search response: <500ms

## 📋 **Pull Request Process**

### 1. Create Feature Branch
```bash
git checkout -b feature/description-of-change
git checkout -b bugfix/issue-number-description
git checkout -b hotfix/critical-issue-description
```

### 2. Development Workflow
- Make focused, atomic commits
- Write clear commit messages
- Update tests for new functionality
- Update documentation if needed

### 3. Commit Message Format
```
type(scope): brief description

Detailed explanation of changes made and why.

Closes #issue-number
```

**Types**: feat, fix, docs, style, refactor, test, chore

**Examples**:
```
feat(capture): add WhatsApp integration support

Implemented share extension handling for WhatsApp images and text.
Added context detection for contact names and message metadata.

Closes #123
```

### 4. Pull Request Template
- Use the provided PR template
- Include screenshots for UI changes
- Reference related issues
- Describe testing performed

### 5. Review Process
- Automated CI checks must pass
- Code review by maintainer required
- Address feedback promptly
- Squash commits before merge

## 🐛 **Bug Reports**

### Before Reporting
- Search existing issues
- Test on latest version
- Reproduce on clean install

### Bug Report Template
```markdown
**Description**: Brief description of the issue

**Steps to Reproduce**:
1. Step one
2. Step two
3. Step three

**Expected Behavior**: What should happen

**Actual Behavior**: What actually happens

**Environment**:
- iOS Version: 
- Device Model:
- App Version:

**Additional Context**: Screenshots, logs, etc.
```

## ✨ **Feature Requests**

### Feature Request Template
```markdown
**Problem Statement**: What problem does this solve?

**Proposed Solution**: Detailed description of the feature

**User Impact**: How will this improve the user experience?

**Technical Considerations**: Any implementation concerns

**Alternatives Considered**: Other approaches evaluated
```

## 🚀 **Release Process**

### Version Numbering
- Follow [Semantic Versioning](https://semver.org/)
- Format: `MAJOR.MINOR.PATCH`
- Example: `1.2.3`

### Release Checklist
- [ ] All tests passing
- [ ] Version number updated
- [ ] CHANGELOG.md updated
- [ ] App Store assets prepared
- [ ] TestFlight testing completed
- [ ] Documentation updated

## 🏷️ **Issue Labels**

| Label | Description |
|-------|-------------|
| `bug` | Something isn't working |
| `enhancement` | New feature or improvement |
| `documentation` | Documentation updates |
| `good first issue` | Good for newcomers |
| `help wanted` | Community help needed |
| `priority: high` | Urgent issue |
| `platform: ios` | iOS-specific issue |
| `area: ai` | AI/ML processing related |
| `area: ui` | User interface related |

## 🤝 **Community Guidelines**

### Code of Conduct
- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers learn
- Maintain professional communication

### Getting Help
- **Documentation**: Check README and architecture docs first
- **Discussions**: Use GitHub Discussions for questions
- **Issues**: Use GitHub Issues for bugs and features
- **Discord**: Join our development community (link in README)

## 🎖️ **Recognition**

Contributors are recognized in:
- README.md contributors section
- Release notes for major contributions
- Special recognition for significant improvements

## 📚 **Additional Resources**

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Core Data Programming Guide](https://developer.apple.com/documentation/coredata/)

---

Thank you for contributing to SnapNotion! Together we're building the future of intelligent content management. 🚀