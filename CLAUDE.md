# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of self-developed Cheat Engine tables (.CT files) for various video games. Each game directory contains cheat tables along with documentation files (README.md, CHANGELOG.md, CHEATLIST.txt) that describe available cheats and modifications.

## Project Structure

- **Game directories**: Each game has its own folder containing:
  - `.CT` files - Cheat Engine table files (XML format)
  - `README.md` - Game-specific information and setup instructions
  - `CHANGELOG.md` - Version history and updates
  - `CHEATLIST.txt` - List of available cheats/modifications
- **ZZ_Tools/**: Development tools and utilities for managing cheat tables
- **TITLELIST.md**: Complete list of all games with multi-language titles
- **LICENSE**: GPL v3 license

## Cheat Engine Table Architecture

Cheat tables (.CT files) are XML-based files with the following structure:
- **CheatEntries**: Root container for all cheat modifications
- **Auto Assembler Scripts**: Lua-based scripts for complex modifications
- **Memory Records**: Direct memory address modifications
- **Hierarchical organization**: Entries can be nested with parent-child relationships

Common patterns in the tables:
- Compact view mode toggles for UI management
- AOB (Array of Bytes) scanning for dynamic memory location finding
- Lua scripts for advanced functionality
- ID-based entry management system

## Development Tools

### AAToggleGenerator (C# WinForms Application)
Located in `ZZ_Tools/AAToggleGenerator/`:
- Generates Lua On/Off scripts for Cheat Engine tables
- Parses .CT files and creates hierarchical TreeView for entry selection
- Uses Scintilla for syntax highlighting
- Built with .NET Framework 4.8

### Standard Lua Scripts
`ZZ_Tools/Cheat Table lua script std.txt` contains:
- AOB scanning utilities for finding memory patterns within specific modules
- Memory record management functions
- UI enhancement functions (compact view, log management)
- Event handling for cheat activation/deactivation

## Git Workflow

The repository uses a `dev` → `main` branch workflow as documented in `ZZ_Tools/git-workflow.md`:
- Daily development happens on `dev` branch
- Pull requests merge `dev` to `main` for stable releases
- Both branches are kept synchronized after merges

## Common Operations

### Working with Cheat Tables
- Tables are XML files that can be edited directly or through Cheat Engine 7.5+
- Lua scripts within tables use special syntax: `{$lua}` blocks
- Memory addresses are typically dynamic and use AOB scanning

### File Naming Conventions
- Game directories use full game titles
- CT files often match executable names (e.g., `A13V_x64_Release.CT`)
- Multi-language titles included for Japanese and Chinese markets

### Documentation Standards
Each game folder maintains:
- Consistent README format with game information and compatibility
- Changelog tracking updates and fixes
- Cheat list documenting available modifications

## Publishing and Distribution

All tables are published on OpenCheatTables.com (https://opencheattables.com). The repository serves as the primary source, with proper attribution required for redistribution.

## Requirements

- Cheat Engine 7.5 or later
- Windows platform (tables target Windows games)
- Understanding of memory editing and assembly language for modifications

## Notes

- Tables may not always be up-to-date with latest game versions
- Game updates can break memory addresses and require table updates  
- Some directories contain auxiliary files like Excel spreadsheets for item/effect lists
- PowerShell scripts in some folders provide additional utilities for specific games