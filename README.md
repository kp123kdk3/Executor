# Executor - Dynamic Lua Scripting System

A MacOS application for dynamic Lua scripting inside live processes.

## Features

- Dynamic library injection into user-mode applications
- Lua Virtual Machine interaction and hooking
- Runtime scripting system with Luau bytecode support
- SwiftUI-based GUI for script management
- Memory integrity and security measures

## Project Structure

```
/Loader/
   mac_dynamic_loader.mm - Dynamic library injection implementation
/Hooking/
   lua_interaction.mm - Lua VM interaction and hooking
/Frontend/
   ScriptingInterfaceApp.swift - Main GUI application
/Scripting/
   lua_script_engine.cpp - Lua script engine implementation
/Security/
   memory_integrity.mm - Memory protection and integrity checks
```

## Requirements

- MacOS 13 Ventura or newer
- Xcode 14.0 or newer
- Lua 5.4 or Luau

## Building

1. Open the project in Xcode
2. Select the appropriate target
3. Build and run

## Security Notice

This project is for educational purposes only. Use responsibly and in accordance with applicable laws and regulations.

## License

MIT License 