# Kafra Desktop Assistant - Technical Documentation

## Overview

The Kafra Desktop Assistant (KDA) is a desktop companion application for Windows, inspired by the Kafra characters from Ragnarok Online. It provides memo storage, file organization, and an animated desktop mascot with advanced form shaping and transparency effects.

**Version:** 1.0  
**Platform:** Windows 98/ME/2000/XP (VB6 Application)  
**Language:** Visual Basic 6.0  
**Original Author:** David Santos (EnderSoft)

## Documentation Structure

This documentation follows the Diataxis framework, organizing content by purpose:

### [1. Tutorials](tutorials/index.md)
Step-by-step learning-oriented guides for getting started with KDA development and modification.

### [2. How-To Guides](how-to/index.md)
Task-oriented guides for accomplishing specific goals with the codebase.

### [3. Technical Reference](reference/index.md)
Information-oriented technical specifications of the system, APIs, modules, and data structures.

### [4. Explanation](explanation/index.md)
Understanding-oriented discussions of key concepts, architectural decisions, and design patterns.

### [5. Migration Guide](migration/index.md)
Platform-specific guidance for recreating KDA on different operating systems (Linux, macOS).

## Quick Navigation

- **[System Architecture](explanation/architecture.md)** - High-level overview of the application structure
- **[API Reference](reference/api-reference.md)** - Windows API declarations and usage
- **[Forms Reference](reference/forms-reference.md)** - Complete form catalog and purposes
- **[Module Reference](reference/modules-reference.md)** - BAS module functionality
- **[Class Reference](reference/classes-reference.md)** - VB6 class documentation
- **[Data Structures](reference/data-structures.md)** - Types and storage mechanisms
- **[Security Considerations](explanation/security.md)** - Registry access and permissions
- **[Cross-Platform Migration](migration/overview.md)** - Recreating KDA on other platforms

## Key Features

- **Form Shaping**: Non-rectangular windows using region-based transparency
- **Subclassing**: Custom window message handling without crashes
- **Resource Management**: Efficient bitmap and region storage
- **System Tray Integration**: Minimize to tray with custom icons
- **OLE Drag-and-Drop**: File management through drag operations
- **Registry Integration**: Persistent settings and autorun capability
- **Transparency Effects**: Windows 2000/XP layered window support
- **Custom Controls**: Ragnarok-themed UI components

## Technology Stack

| Component | Technology |
|-----------|------------|
| **Primary Language** | Visual Basic 6.0 |
| **Graphics** | GDI (Device Independent Bitmaps) |
| **Window Management** | Win32 API Subclassing |
| **Storage** | Windows Registry, File System |
| **UI Framework** | VB Forms, Custom Controls |
| **Resource Format** | .res files (compiled resources) |

## Project Editions

The project includes two editions:

1. **Original Edition** - Features 7 original Kafra characters
2. **Sakura Edition** - Features alternative Kafra character set with blink animations

## Legal and Compliance

- Fan work with no affiliation to Gravity, Inc. or Level-Up-Games
- Educational and reference purposes
- See [LICENSE](../LICENSE.md) for usage terms
- Ragnarok Online is property of Gravity Co., Ltd.

## Contributing to Documentation

This documentation is designed to enable complete reconstruction of the application on any platform. If you find gaps or errors, please update the relevant section following the [Google Developer Style Guide](https://developers.google.com/style).

---

**Last Updated:** 2026-01-20  
**Documentation Version:** 1.0
