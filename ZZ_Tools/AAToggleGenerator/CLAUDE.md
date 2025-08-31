# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AAToggleGenerator is a C# WinForms application designed to help users generate Lua On/Off scripts for Cheat Engine tables. The application parses Cheat Engine .CT files (XML format) and provides utilities for managing and customizing cheat table entries.

## Build and Development Commands

### Building the Application
```bash
# Build Debug version
msbuild AAToggleGenerator.sln /p:Configuration=Debug

# Build Release version  
msbuild AAToggleGenerator.sln /p:Configuration=Release

# Using Visual Studio
# Open AAToggleGenerator.sln in Visual Studio 2017 or later
# Build > Build Solution (Ctrl+Shift+B)
```

### Running the Application
```bash
# Run Debug build
.\bin\Debug\AAToggleGenerator.exe

# Run Release build
.\bin\Release\AAToggleGenerator.exe
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

- **.NET Framework 4.8**: Target framework for Windows compatibility
- **ScintillaNET 3.6.3**: Provides syntax highlighting for Lua script editor
- **System.Xml.Linq**: Used for parsing and manipulating .CT file XML structure

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