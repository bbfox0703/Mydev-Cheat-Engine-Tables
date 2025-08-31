# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AAToggleGenerator is a C# WinForms application designed to help users generate Lua On/Off scripts for Cheat Engine tables. The application parses Cheat Engine .CT files (XML format) and provides utilities for managing and customizing cheat table entries.

## Build and Development Commands

### Building the Application
```bash
# Build Debug version
dotnet build

# Build Release version
dotnet build -c Release

# Restore dependencies
dotnet restore
```

### Running the Application
```bash
# Run Debug build
dotnet run

# Run Release build
dotnet run -c Release

# Or run directly from output
.\bin\Debug\net8.0-windows\AAToggleGenerator.exe
.\bin\Release\net8.0-windows\AAToggleGenerator.exe
```

## Architecture Overview

### Core Components

1. **MainForm.cs**: The main UI entry point with three primary functions and Windows theme support:
   - AA Toggle Generator (ScriptGenerator.StartScriptGeneration)
   - ID Renumbering (CTFileIDProcessor.RenumberIDs) 
   - Process Name Replacement (CTRenameEXE2Process.ReplaceProcessName)
   - Automatic theme detection and UI styling based on Windows theme

2. **ScriptGenerator.cs**: Core logic for parsing .CT files and generating Lua scripts:
   - Parses XML structure of Cheat Engine tables
   - Creates hierarchical TreeView for entry selection
   - Generates [ENABLE]/[DISABLE] Lua script blocks
   - Uses Scintilla editor for syntax-highlighted script display

3. **CTFileIDProcessor.cs**: Utility for renumbering ID nodes in .CT files using regex pattern matching

4. **CTRenameEXE2Process.cs**: Utility for replacing executable names with `$process` in aobscanmodule and aobscanregion commands

5. **WindowsThemeHelper.cs**: Windows theme detection and management utility:
   - Detects Windows 10 1903+ support for theme awareness
   - Registry-based dark/light theme detection
   - Provides theme-appropriate colors for UI elements
   - **DWM API integration**: Uses DwmSetWindowAttribute for native title bar theming
   - Supports both Windows 10 1903-1909 and 2004+ title bar attributes

6. **ThemeExtensions.cs**: Extension methods for applying Windows themes to controls:
   - Form, Button, Label, TreeView, NumericUpDown theme styling
   - **Title bar theming**: Automatic dark/light title bar application
   - Scintilla editor dark/light theme with syntax highlighting
   - Automatic theme application to all UI elements

### Key Dependencies

- **.NET 8**: Modern cross-platform framework targeting Windows
- **fernandreu.ScintillaNET 4.2.0**: Provides syntax highlighting for Lua script editor (.NET 6+ compatible)
- **System.Xml.Linq**: Used for parsing and manipulating .CT file XML structure
- **Windows Forms**: UI framework for Windows desktop applications
- **Microsoft.Win32.Registry**: For Windows theme detection via registry access

### Application Flow

1. **File Selection**: User selects a .CT file via OpenFileDialog
2. **XML Parsing**: Application parses the XML structure to extract CheatEntry nodes
3. **TreeView Display**: Entries are displayed hierarchically based on depth and parent-child relationships
4. **Script Generation**: Selected entries generate Lua scripts with:
   - ENABLE section: Activates entries in ascending hierarchical order
   - DISABLE section: Deactivates all entries in reverse hierarchical order
5. **Syntax Highlighting**: Generated scripts displayed in Scintilla editor with Lua syntax highlighting

### Cheat Engine Table Structure

The application specifically looks for entries with:
- `Auto Assembler Script` types
- Entries with `moHideChildren=1` option
- Hierarchical parent-child relationships via ID references
- Exclusion of certain keywords ("一鍵開啟", "Toggle Scripts", etc.)

### Performance Considerations

- Uses HashSet for exclusion keyword matching (O(1) lookup)
- Pre-compiled regex patterns for efficient XML processing
- StringBuilder with default capacity for script generation
- Optimized TreeView expansion controls

## File Conventions

- **.CT files**: Cheat Engine table files in XML format
- **Entry IDs**: Sequential numbering system for cheat table entries
- **Process names**: Executable names that can be replaced with `$process` variable
- **Lua script format**: Standard [ENABLE]/[DISABLE] block structure for Cheat Engine

## Development Notes

- **Upgraded to .NET 8**: Modernized from .NET Framework 4.8 for better performance and long-term support
- **SDK-style project format**: Simplified project file structure with modern package references
- **Nullable reference types**: Enhanced with null safety features for better code reliability
- **Windows Theme Aware**: Supports Windows 10/11 dark and light themes
  - Automatic theme detection for Windows 10 1903+ (Build 18362+)
  - Falls back to light theme for older Windows versions
  - Theme-aware UI styling for all dialogs and controls
  - **Dark title bars**: Uses DwmSetWindowAttribute API for native title bar theming
  - Dark mode syntax highlighting for Scintilla code editor
- **DPI Configuration**:
  - Runtime: SystemAware DPI mode for proper high-resolution display support
  - Designer: ForceDesignerDpiUnaware for better Visual Studio design experience
- Uses consistent error handling with MessageBox displays
- Maintains backwards compatibility with older .CT file formats
- Supports both Chinese and English interface elements (based on exclusion keywords)

## Testing

### Test Framework
Comprehensive testing documentation and test cases are available:
- **TESTING.md**: Detailed testing guide with scenarios and procedures
- **TestData/**: Sample CT files for various test scenarios

### Test Categories
1. **Unit Tests**: Component isolation and method validation
2. **Integration Tests**: End-to-end workflow testing
3. **UI Theme Tests**: Dark/light mode functionality validation
4. **Compatibility Tests**: Multi-version Windows testing
5. **Performance Tests**: Large file processing benchmarks

### Manual Testing Procedures
1. Loading various .CT files to verify XML parsing
2. Verifying TreeView hierarchy display and theme application
3. Testing generated Lua script syntax and accuracy
4. Validating ID renumbering functionality
5. Confirming process name replacement accuracy
6. Theme switching and UI consistency testing
7. Error handling and edge case validation

### Test Data
- **sample_simple.CT**: Basic functionality testing
- **sample_complex.CT**: Advanced features and performance
- **sample_corrupted.CT**: Error handling validation
- **sample_empty.CT**: Edge case testing
- **sample_unicode.CT**: Internationalization support

### Performance Benchmarks
- Small CT files (<1MB): <2 seconds processing
- Medium CT files (1-10MB): <5 seconds processing
- Large CT files (>10MB): <15 seconds processing
- Memory usage: <100MB for typical operations