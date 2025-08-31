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

1. **MainForm.cs**: The main UI entry point with three primary functions:
   - AA Toggle Generator (ScriptGenerator.StartScriptGeneration)
   - ID Renumbering (CTFileIDProcessor.RenumberIDs) 
   - Process Name Replacement (CTRenameEXE2Process.ReplaceProcessName)

2. **ScriptGenerator.cs**: Core logic for parsing .CT files and generating Lua scripts:
   - Parses XML structure of Cheat Engine tables
   - Creates hierarchical TreeView for entry selection
   - Generates [ENABLE]/[DISABLE] Lua script blocks
   - Uses Scintilla editor for syntax-highlighted script display

3. **CTFileIDProcessor.cs**: Utility for renumbering ID nodes in .CT files using regex pattern matching

4. **CTRenameEXE2Process.cs**: Utility for replacing executable names with `$process` in aobscanmodule and aobscanregion commands

### Key Dependencies

- **.NET 8**: Modern cross-platform framework targeting Windows
- **fernandreu.ScintillaNET 4.2.0**: Provides syntax highlighting for Lua script editor (.NET 6+ compatible)
- **System.Xml.Linq**: Used for parsing and manipulating .CT file XML structure
- **Windows Forms**: UI framework for Windows desktop applications

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
- Application is DPI-aware for high-resolution displays
- Uses consistent error handling with MessageBox displays
- Maintains backwards compatibility with older .CT file formats
- Supports both Chinese and English interface elements (based on exclusion keywords)

## Testing

No automated test framework is configured. Manual testing involves:
1. Loading various .CT files to verify XML parsing
2. Verifying TreeView hierarchy display
3. Testing generated Lua script syntax
4. Validating ID renumbering functionality
5. Confirming process name replacement accuracy