# AAToggleGenerator Testing Guide

This document outlines test cases, scenarios, and testing procedures for the AAToggleGenerator application.

## 🧪 Test Categories

### Unit Tests
Testing individual components and methods in isolation.

### Integration Tests
Testing component interactions and complete workflows.

### UI Tests
Testing user interface behavior and theme functionality.

### Compatibility Tests
Testing across different Windows versions and configurations.

## 🎯 Test Scenarios

### Core Functionality Tests

#### 1. CT File Processing
- **Valid CT file parsing**
- **Invalid/corrupted CT file handling**
- **Large CT file performance**
- **Empty CT file handling**
- **CT files with special characters**

#### 2. Script Generation
- **Basic AA script generation**
- **Complex hierarchical entries**
- **Mixed entry types**
- **Edge cases with empty selections**
- **Large scale script generation**

#### 3. ID Renumbering
- **Sequential ID assignment**
- **Duplicate ID handling**
- **Missing ID recovery**
- **Large file processing**
- **Backup and recovery**

#### 4. Process Name Replacement
- **Standard exe name replacement**
- **Multiple exe name instances**
- **Edge case exe names**
- **AOB scan command variations**
- **Regex pattern matching**

### Theme Awareness Tests

#### 5. Windows Theme Detection
- **Windows 10 1903+ dark theme detection**
- **Windows 10 1903+ light theme detection**
- **Windows 10 1809 and below fallback**
- **Theme switching during runtime**
- **Registry access failure handling**

#### 6. UI Theme Application
- **Main form theme application**
- **Dialog theme consistency**
- **TreeView theme styling**
- **Button and control theming**
- **Scintilla editor theme modes**

#### 7. Title Bar Theming
- **Dark title bar application**
- **Light title bar application**
- **DWM API failure handling**
- **Multiple window instances**
- **Window focus/unfocus behavior**

### System Integration Tests

#### 8. DPI Awareness
- **High DPI display scaling**
- **Multi-monitor DPI differences**
- **DPI change during runtime**
- **Designer vs runtime DPI modes**
- **Text and control scaling**

#### 9. File System Operations
- **File access permissions**
- **Long path handling**
- **Unicode filename support**
- **Network drive compatibility**
- **Concurrent file access**

#### 10. Error Handling
- **Graceful error recovery**
- **User-friendly error messages**
- **Log file generation**
- **Memory leak prevention**
- **Resource cleanup**

## 🔬 Detailed Test Cases

### Test Case 1: Basic AA Script Generation

**Objective**: Verify basic Auto Assembler script generation functionality

**Prerequisites**: 
- Valid CT file with AA script entries
- Application launched successfully

**Steps**:
1. Launch AAToggleGenerator
2. Click "Generate AA bulk toggle script"
3. Select a valid CT file with AA scripts
4. Verify TreeView displays entries correctly
5. Select desired entries
6. Click "Confirm"
7. Verify generated script syntax
8. Check ENABLE/DISABLE sections

**Expected Results**:
- TreeView shows hierarchical structure
- Selected entries generate proper Lua code
- ENABLE section has ascending order
- DISABLE section has descending order
- Script includes metadata comments

**Test Data**:
```xml
<!-- Sample CT file content -->
<CheatTable>
  <CheatEntries>
    <CheatEntry>
      <ID>1</ID>
      <Description>Test Script</Description>
      <VariableType>Auto Assembler Script</VariableType>
      <AssemblerScript>// Test code here</AssemblerScript>
    </CheatEntry>
  </CheatEntries>
</CheatTable>
```

### Test Case 2: Windows Theme Detection

**Objective**: Verify Windows theme detection across different OS versions

**Prerequisites**: 
- Different Windows versions for testing
- Admin rights for registry access

**Steps**:
1. Set Windows to dark mode
2. Launch application
3. Verify theme detection
4. Check title display
5. Switch to light mode
6. Restart application
7. Verify theme change

**Expected Results**:
- Windows 10 1903+: Correct theme detection
- Windows 10 1809-: Falls back to light theme
- Title shows "- Dark Theme" or "- Light Theme"
- UI elements match system theme

### Test Case 3: CT File ID Renumbering

**Objective**: Test ID renumbering functionality for CT files

**Prerequisites**:
- CT file with non-sequential IDs
- Backup of original file

**Steps**:
1. Click "Reassign .CT <ID> tag"
2. Select CT file with mixed IDs
3. Process the file
4. Verify success message
5. Check output file
6. Validate ID sequence

**Expected Results**:
- IDs renumbered sequentially (1, 2, 3, ...)
- XML structure preserved
- No data loss
- File backup created

### Test Case 4: Scintilla Editor Theme

**Objective**: Test syntax highlighting in different themes

**Prerequisites**:
- Generated Lua script
- Both dark and light system themes

**Steps**:
1. Generate a Lua script
2. Verify syntax highlighting in current theme
3. Switch system theme
4. Generate another script
5. Compare syntax highlighting

**Expected Results**:
- Dark theme: VS Code-style dark colors
- Light theme: Standard bright colors
- Keywords properly highlighted
- Comments in appropriate colors

### Test Case 5: DPI Scaling

**Objective**: Test application behavior on high DPI displays

**Prerequisites**:
- High DPI monitor (150%, 200%, 250%)
- Different DPI settings

**Steps**:
1. Set display to 150% scaling
2. Launch application
3. Verify UI element scaling
4. Test all dialogs and windows
5. Change to 200% scaling
6. Repeat verification

**Expected Results**:
- All text remains readable
- Controls scale proportionally
- No UI element overlap
- Consistent spacing maintained

## 🚨 Edge Cases and Error Scenarios

### Error Scenario 1: Corrupted CT File

**Test Input**: CT file with malformed XML
**Expected**: Graceful error message, no crash

### Error Scenario 2: Registry Access Denied

**Test Input**: Limited user account without registry access
**Expected**: Falls back to light theme, continues operation

### Error Scenario 3: DWM API Unavailable

**Test Input**: Older Windows version without DWM support
**Expected**: Standard title bars, no functionality loss

### Error Scenario 4: Memory Pressure

**Test Input**: Large CT files (>100MB)
**Expected**: Reasonable performance, no memory leaks

### Error Scenario 5: File System Permissions

**Test Input**: Read-only CT files or protected directories
**Expected**: Clear error messages, alternative suggestions

## 🎨 Theme Testing Matrix

| OS Version | Theme | Title Bar | UI Elements | Expected Result |
|-----------|-------|-----------|-------------|----------------|
| Win 10 1903+ | Dark | Dark | Dark | ✅ Full dark mode |
| Win 10 1903+ | Light | Light | Light | ✅ Full light mode |
| Win 10 1809- | Dark | Default | Light | ⚠️ Partial support |
| Win 10 1809- | Light | Default | Light | ✅ Light mode |
| Win 11 | Dark | Dark | Dark | ✅ Full dark mode |
| Win 11 | Light | Light | Light | ✅ Full light mode |

## 🔄 Regression Testing

### Critical Features Checklist
- [ ] CT file parsing and loading
- [ ] TreeView hierarchy display
- [ ] Script generation accuracy
- [ ] Theme detection and application
- [ ] File operations (save, backup)
- [ ] Error handling and recovery
- [ ] Memory management
- [ ] UI responsiveness

## 📊 Performance Testing

### Performance Benchmarks
- **Small CT file** (<1MB): <2 seconds processing
- **Medium CT file** (1-10MB): <5 seconds processing  
- **Large CT file** (>10MB): <15 seconds processing
- **Memory usage**: <100MB for typical operations
- **UI response time**: <200ms for user interactions

## 🛠️ Test Environment Setup

### Required Software
- Windows 10 1809+ / Windows 11
- .NET 8 Runtime
- Cheat Engine 7.5+ (for test data creation)
- Visual Studio 2022 (for development testing)

### Test Data Requirements
- Small CT files (basic functionality)
- Large CT files (performance testing)
- Corrupted CT files (error handling)
- Empty CT files (edge cases)
- Unicode CT files (internationalization)

### Hardware Requirements
- Multiple DPI displays (100%, 150%, 200%)
- Various screen resolutions
- Different Windows theme settings
- Limited memory environments (for stress testing)

## 📝 Test Reporting

### Test Report Template
```
Test Case: [Name]
Date: [Date]
Tester: [Name]
OS Version: [Version]
Theme: [Dark/Light]
DPI: [Scaling %]

Results:
- [ ] Pass
- [ ] Fail
- [ ] Partial

Notes:
[Detailed observations]

Bugs Found:
[List any issues discovered]
```

## 🚀 Automated Testing Future

### Potential Automation
- Unit tests for core parsing logic
- Theme detection mock testing  
- File operation integration tests
- UI automation with Windows Application Driver
- Performance regression testing
- Memory leak detection

### Testing Tools Consideration
- MSTest/NUnit for unit testing
- Moq for mocking dependencies
- MemoryProfiler for leak detection
- UI automation frameworks
- Continuous integration testing

---

*This testing guide ensures comprehensive coverage of all AAToggleGenerator functionality and provides a solid foundation for quality assurance.*