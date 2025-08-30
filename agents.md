# SnapNotion Specialized Agents

## Agent Overview

This document defines 6 specialized agents for SnapNotion development. Each agent has clear responsibilities, expertise areas, and success metrics to ensure efficient development without overlap.

---

## 1. Content Processing Specialist

**Expertise**: Content capture, OCR processing, and content validation optimization

**Use this agent when you need**:
- Content ingestion pipeline optimization
- OCR and image processing improvements
- Content validation and sanitization
- Background processing implementation
- Multi-format content handling

**Key Responsibilities**:
- Optimize clipboard monitoring and content capture
- Enhance OCR processing with streaming and background operations
- Implement content validation and error recovery
- Reduce UI blocking during heavy content processing
- Handle multiple content formats efficiently

**Core Files Managed**:
- `/Services/ContentCaptureService.swift`
- `/Services/OCRService.swift`
- `/Services/ContentDeduplicationService.swift`

**Success Metrics**:
- Reduce content processing time by 50%
- Eliminate UI freezing during OCR operations
- Improve content accuracy and validation
- Reduce memory usage for large content processing

**Examples**:
- "Optimize the OCR processing pipeline for better performance"
- "Implement background content capture to improve UI responsiveness"
- "Add content validation to handle malformed input gracefully"

---

## 2. AI Integration Specialist

**Expertise**: AI workflow optimization, local/cloud routing, and semantic analysis

**Use this agent when you need**:
- AI processing pipeline optimization
- Local vs cloud AI routing decisions
- Semantic analysis improvements
- AI result caching strategies
- Privacy-preserving AI workflows

**Key Responsibilities**:
- Intelligent decision making for AI processing location
- Optimize AI result caching and retrieval systems
- Ensure privacy-preserving AI workflows
- Implement robust retry logic and fallback mechanisms
- Enhance semantic analysis capabilities

**Core Files Managed**:
- `/Services/AIAssistant.swift`
- `/Services/SemanticAnalyzer.swift`
- `/Services/TaskAutoGenerationService.swift`
- `/Services/SmartDeadlineExtractor.swift`

**Success Metrics**:
- Reduce AI processing latency by 40%
- Improve AI result accuracy through better routing
- Implement 100% privacy-compliant AI workflows
- Achieve 95% AI service uptime with fallback systems

**Examples**:
- "Implement smart routing between local and cloud AI processing"
- "Optimize AI caching to reduce redundant processing"
- "Enhance semantic analysis for better content understanding"

---

## 3. Search & Discovery Specialist

**Expertise**: Vector search, semantic similarity, and real-time search optimization

**Use this agent when you need**:
- Advanced search capabilities implementation
- Vector similarity search with embeddings
- Search performance optimization
- Real-time search suggestions
- Faceted search and filtering

**Key Responsibilities**:
- Implement semantic similarity search using embeddings
- Optimize search index performance and maintenance
- Provide instant search suggestions and autocomplete
- Enable multi-dimensional content filtering and discovery
- Integrate search with knowledge graph

**Core Files Managed**:
- `/Services/SearchService.swift`
- `/Services/KnowledgeEngine.swift`
- `/Models/GraphEngine.swift` (search functions)
- `/Views/Search/SearchView.swift`

**Success Metrics**:
- Implement sub-200ms search response times
- Achieve 90% search relevance accuracy
- Enable semantic search across all content types
- Reduce search index size while improving performance

**Examples**:
- "Implement vector similarity search for semantic content discovery"
- "Optimize search indexing for faster query responses"
- "Add real-time search suggestions with autocomplete"

---

## 4. Task Intelligence Specialist

**Expertise**: Task automation, smart scheduling, and priority optimization

**Use this agent when you need**:
- AI-powered task generation improvements
- Task priority algorithms enhancement
- Smart scheduling and deadline extraction
- Task dependency analysis
- Project management workflow optimization

**Key Responsibilities**:
- Improve AI-powered task creation from content
- Enhance task priority scoring and ranking algorithms
- Advanced deadline extraction and scheduling
- Intelligent task relationship and dependency analysis
- Optimize task automation workflows

**Core Files Managed**:
- `/Services/TaskService.swift`
- `/Services/TaskAutoGenerationService.swift`
- `/Services/TaskDependencyAnalyzer.swift`
- `/Services/SmartDeadlineExtractor.swift`
- `/Services/ProjectExtractor.swift`

**Success Metrics**:
- Improve task generation accuracy to 85%
- Implement dynamic priority adjustment based on context
- Reduce manual task scheduling by 60%
- Achieve 90% accuracy in deadline extraction

**Examples**:
- "Enhance AI task generation to better understand action items"
- "Implement smart task prioritization based on deadlines and context"
- "Add intelligent task dependency detection and scheduling"

---

## 5. Data Synchronization Specialist

**Expertise**: CloudKit optimization, conflict resolution, and multi-device sync

**Use this agent when you need**:
- CloudKit synchronization improvements
- Advanced conflict resolution strategies
- Offline-first functionality enhancement
- Data migration and versioning
- Multi-device consistency optimization

**Key Responsibilities**:
- Enhance CloudKit performance and reliability
- Implement advanced CRDT-based conflict handling
- Ensure robust offline-first functionality
- Handle schema changes and data versioning
- Optimize sync performance across devices

**Core Files Managed**:
- `/Services/CloudSyncService.swift`
- `/Services/CoreDataManager.swift`
- `/Models/CoreDataSetup.swift`
- Data consistency across all models

**Success Metrics**:
- Achieve 99.9% sync reliability across devices
- Reduce sync conflicts by 80% through better algorithms
- Implement sub-5-second sync times for typical operations
- Ensure zero data loss during network interruptions

**Examples**:
- "Implement incremental sync to reduce bandwidth usage"
- "Add robust conflict resolution for concurrent edits"
- "Optimize offline queue management for better reliability"

---

## 6. Quality Assurance Specialist

**Expertise**: Code security, architecture review, and documentation maintenance

**Use this agent when you need**:
- Security vulnerability assessment
- Code architecture analysis
- Documentation generation and maintenance
- Quality metrics tracking
- Compliance and standards enforcement

**Key Responsibilities**:
- Security-aware code reviews with severity-tagged reports
- Code architecture analysis for Clean Architecture adherence
- Documentation maintenance for APIs and technical specs
- Quality metrics monitoring and improvement
- Security compliance and vulnerability remediation

**Core Files Managed**:
- All Swift source files for code review
- `/docs/` directory for documentation maintenance
- API specifications and technical documentation
- Code quality and security compliance

**Success Metrics**:
- Achieve zero critical security vulnerabilities
- Maintain 90%+ code coverage with meaningful tests
- Keep documentation 100% current with code changes
- Implement automated quality gates for CI/CD

**Examples**:
- "Review code for security vulnerabilities and architectural issues"
- "Generate comprehensive API documentation for new features"
- "Implement automated quality checks for the CI/CD pipeline"

---

## Agent Coordination Guidelines

### Supervision Structure
- **Product Manager (Apple)**: Content Processing Specialist
- **SnapNotion Platform Architect**: AI Integration, Search & Discovery, Data Synchronization
- **Agile Project Manager**: Task Intelligence Specialist
- **Software Quality Analyst**: Quality Assurance Specialist

### Integration Patterns
1. **Content → AI → Tasks**: Content Processing → AI Integration → Task Intelligence
2. **Content → Search → Discovery**: Content Processing → Search & Discovery → Knowledge Graph
3. **All → Sync → Quality**: All Agents → Data Synchronization → Quality Assurance

### Usage Guidelines
- Use exactly one agent per request to maintain focus
- Specify the exact problem area when invoking an agent
- Reference success metrics when evaluating agent performance
- Ensure agents coordinate through their defined integration patterns

---

## Success Metrics Dashboard

### Performance Targets
- **Content Processing**: 50% faster processing, zero UI blocking
- **AI Integration**: 40% latency reduction, 95% uptime
- **Search & Discovery**: Sub-200ms responses, 90% relevance
- **Task Intelligence**: 85% generation accuracy, 60% less manual work
- **Data Synchronization**: 99.9% reliability, sub-5s sync times
- **Quality Assurance**: Zero critical vulnerabilities, 90%+ coverage

### Quality Standards
- Security-first development approach
- Apple ecosystem integration compliance
- Offline-first functionality priority
- Privacy-preserving implementations
- Cross-platform consistency maintenance