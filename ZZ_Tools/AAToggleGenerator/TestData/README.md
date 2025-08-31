# Test Data Files

This directory contains sample CT files for testing AAToggleGenerator functionality.

## 📁 Test Files

### `sample_simple.CT`
**Purpose**: Basic functionality testing
**Contents**: 
- Simple AA script entry
- Nested entries with parent-child relationships
- Group header with hidden children
- Mixed entry types (AA scripts and regular entries)

**Use Cases**:
- Basic script generation testing
- TreeView hierarchy display
- Simple selection scenarios

### `sample_complex.CT`
**Purpose**: Advanced functionality and performance testing
**Contents**:
- Multiple nested AA scripts
- Complex AOB scan patterns
- Chinese text (excluded keywords testing)
- Deep hierarchy structures
- Real-world game hacking scenarios

**Use Cases**:
- Complex script generation
- Performance testing with larger files
- Exclusion keyword filtering
- Multi-level hierarchy testing

### `sample_corrupted.CT`
**Purpose**: Error handling testing
**Contents**:
- Malformed XML structure
- Missing closing tags
- Incomplete entries
- Invalid syntax

**Use Cases**:
- XML parsing error handling
- Application stability testing
- User error message validation
- Recovery scenarios

### `sample_empty.CT`
**Purpose**: Edge case testing
**Contents**:
- Valid XML structure
- Empty CheatEntries section
- Minimal valid CT file

**Use Cases**:
- Empty file handling
- Edge case validation
- UI behavior with no entries
- Performance baseline

### `sample_unicode.CT`
**Purpose**: Internationalization testing
**Contents**:
- Multi-language descriptions (Chinese, Japanese, Russian, Korean)
- Unicode characters in comments
- UTF-8 encoding validation

**Use Cases**:
- Unicode text rendering
- International character support
- Font compatibility testing
- Encoding preservation

## 🧪 Testing Scenarios

### Basic Testing Flow
1. Load `sample_simple.CT` → Verify basic functionality
2. Load `sample_complex.CT` → Test advanced features
3. Load `sample_corrupted.CT` → Verify error handling
4. Load `sample_empty.CT` → Test edge cases
5. Load `sample_unicode.CT` → Test internationalization

### Performance Testing
- Load `sample_complex.CT` multiple times
- Monitor memory usage during processing
- Measure script generation time
- Test with multiple concurrent instances

### UI Theme Testing
- Test each sample file in both dark and light themes
- Verify syntax highlighting in both modes
- Check TreeView rendering with different themes
- Validate dialog appearance consistency

### Regression Testing
Use these files as regression test cases:
- After code changes, verify all samples still process correctly
- Check generated script quality remains consistent
- Ensure UI behavior is preserved across updates

## 📋 Expected Test Results

### `sample_simple.CT`
```
Expected TreeView Structure:
- Simple AA Script ✓ (selectable)
- Regular Entry (expandable)
  - Child AA Script ✓ (selectable)
- Group Header (expandable, not selectable)
  - Nested AA Script ✓ (selectable)

Expected Generated Script:
[ENABLE]
-- ID: 0, Desc: Simple AA Script, Depth: 0
-- ID: 2, Desc: Child AA Script, Depth: 1  
-- ID: 4, Desc: Nested AA Script, Depth: 1

[DISABLE]
-- ID: 4, Desc: Nested AA Script, Depth: 1
-- ID: 2, Desc: Child AA Script, Depth: 1
-- ID: 0, Desc: Simple AA Script, Depth: 0
```

### `sample_complex.CT`
- Should exclude "一鍵開啟" and "Toggle Scripts" entries
- Should include nested AA scripts
- Should maintain proper hierarchy order
- Should handle complex AOB patterns

### Error Cases
- `sample_corrupted.CT`: Should show XML parsing error
- `sample_empty.CT`: Should show "No valid entries found" message
- Missing files: Should show file not found error

## 🔍 Manual Testing Checklist

### For Each Test File:
- [ ] File loads without errors
- [ ] TreeView displays correct hierarchy
- [ ] Selection works properly  
- [ ] Script generation produces valid output
- [ ] Syntax highlighting works in both themes
- [ ] Error handling is appropriate

### Cross-File Testing:
- [ ] Processing multiple files in sequence
- [ ] Memory cleanup between file loads
- [ ] UI state reset between operations
- [ ] Theme consistency across all files

## 🚀 Automation Opportunities

These test files can be used for future automated testing:

### Unit Tests
- XML parsing validation
- Entry filtering logic
- Script generation algorithms
- Theme detection logic

### Integration Tests  
- End-to-end file processing
- UI workflow automation
- Error scenario validation
- Performance benchmarking

### Regression Tests
- Automated comparison of generated scripts
- UI element verification
- Theme application validation
- Memory leak detection

---

*These test files provide comprehensive coverage for validating AAToggleGenerator functionality across various scenarios and edge cases.*