# AAToggleGenerator

A modern C# WinForms application designed to help users generate Lua On/Off scripts for Cheat Engine tables, featuring Windows theme awareness and advanced UI capabilities.

## 🚀 Features

### Core Functionality
- **AA Toggle Script Generation**: Creates Lua scripts with `[ENABLE]` and `[DISABLE]` sections for bulk cheat activation/deactivation
- **CT File ID Renumbering**: Automatically reassigns sequential IDs to cheat table entries
- **Process Name Replacement**: Replaces hardcoded executable names with `$process` variable in AOB scan commands

### Modern UI Experience
- **🎨 Windows Theme Aware**: Automatically adapts to Windows 10/11 dark and light themes
- **🖤 Dark Title Bars**: Native Windows title bar theming using DWM API
- **📱 High DPI Support**: Proper scaling on high-resolution displays
- **🎯 Syntax Highlighting**: Scintilla-powered code editor with theme-aware Lua syntax highlighting

### Technical Features
- **Built on .NET 8**: Modern cross-platform framework with long-term support
- **Theme Detection**: Automatic Windows 10 1903+ theme detection via registry
- **Graceful Fallback**: Works on older Windows versions with standard themes
- **Error Handling**: Robust exception handling with user-friendly error messages

## 🎯 How It Works

### 1. Select Cheat Engine Table File
The program opens a file dialog allowing you to select a `.CT` (Cheat Engine Table) file.

### 2. Parse XML Structure
- Reads the `.CT` file as XML
- Extracts entries with `Auto Assembler Script` types
- Identifies entries with special options (`moHideChildren=1`)
- Builds hierarchical entry relationships

### 3. Interactive TreeView Selection
- Displays entries in a hierarchical TreeView interface
- Shows parent-child relationships based on entry depth
- Numeric selector controls TreeView expansion levels
- Visual differentiation for group nodes and scripts

### 4. Generate Lua Scripts
Based on selected entries, generates two Lua script sections:
- **`[ENABLE]`**: Activates selected entries in ascending hierarchical order
- **`[DISABLE]`**: Deactivates all entries in reverse hierarchical order
- Includes metadata comments (ID, description, depth) for each entry

### 5. Syntax-Highlighted Display
- Generated Lua script shown in Scintilla editor
- Theme-aware syntax highlighting (dark/light modes)
- Professional code editing experience

## 🛠️ Requirements

- **Operating System**: Windows 10/11 (Windows 10 1903+ for full theme support)
- **Runtime**: .NET 8 Runtime
- **Target Software**: Cheat Engine 7.5+

## 🎨 Theme Support

### Supported Platforms
- ✅ **Windows 10 1903+**: Full theme awareness with dark title bars
- ✅ **Windows 10 1809 and below**: Standard light theme
- ✅ **Windows 11**: Complete theme integration

### Theme Features
- Automatic system theme detection
- Dark/light mode syntax highlighting
- Theme-aware UI colors for all controls
- Native Windows title bar theming
- Consistent appearance across all dialogs

## 🔧 Development

### Build Requirements
- Visual Studio 2022 17.8+ or .NET 8 SDK
- Windows SDK (for DWM API support)

### Build Commands
```bash
# Restore dependencies
dotnet restore

# Build Debug version
dotnet build

# Build Release version
dotnet build -c Release

# Run application
dotnet run
```

### Project Structure
- **MainForm**: Primary UI with theme-aware styling
- **ScriptGenerator**: Core logic for CT file parsing and Lua script generation
- **WindowsThemeHelper**: Theme detection and DWM API integration
- **ThemeExtensions**: UI control theme application methods
- **CTFileIDProcessor**: ID renumbering utility
- **CTRenameEXE2Process**: Process name replacement utility

## 📋 Compatibility

- **Cheat Engine**: Compatible with CE 7.5+ table formats
- **File Formats**: Processes XML-based `.CT` files
- **Languages**: Supports both English and Chinese interface elements
- **DPI**: SystemAware runtime scaling with designer-friendly development experience

## 🧪 Testing

### Test Documentation
- **[TESTING.md](TESTING.md)**: Comprehensive testing guide with test cases and scenarios
- **[TestData/](TestData/)**: Sample CT files for testing various scenarios

### Test Categories
- **Unit Tests**: Component isolation testing
- **Integration Tests**: End-to-end workflow validation
- **UI Theme Tests**: Dark/light mode functionality
- **Compatibility Tests**: Cross-version Windows testing
- **Performance Tests**: Large file processing benchmarks

### Quick Test
```bash
# Run application with sample data
dotnet run

# Test files located in:
# - TestData/sample_simple.CT (basic functionality)
# - TestData/sample_complex.CT (advanced features)  
# - TestData/sample_corrupted.CT (error handling)
# - TestData/sample_empty.CT (edge cases)
# - TestData/sample_unicode.CT (internationalization)
```

## 🤝 Contributing

This tool is part of the Mydev Cheat Engine Tables collection. For bug reports or feature requests, please refer to the main repository documentation.

## 📄 License

Licensed under GPL v3 - see the main repository for full license details.

---

*Built with .NET 8 and modern Windows theming capabilities for the best user experience.*