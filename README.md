# Executor

A macOS application for process injection and Lua script execution with memory protection features.

## Features

- Process injection capabilities
- Lua script execution engine
- Memory protection and integrity checks
- SwiftUI-based user interface
- Pattern scanning and function hooking

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Lua 5.4 or later

## Building the Project

1. Clone the repository:
```bash
git clone https://github.com/kp123kdk3/Executor.git
cd Executor
```

2. Install Lua dependencies:
```bash
brew install lua
```

3. Open the project in Xcode:
```bash
open Executor.xcodeproj
```

4. Build and run the project:
   - Select the "Executor" scheme
   - Press ⌘R or click the "Run" button

## Project Structure

- `Frontend/`: SwiftUI-based user interface
- `Loader/`: Process injection implementation
- `Hooking/`: Lua function hooking and pattern scanning
- `Scripting/`: Lua script engine implementation
- `Security/`: Memory protection and integrity checks

## Usage

1. Launch the application
2. Select a target process from the list
3. Enter your Lua script in the editor
4. Click "Inject Library" to inject the required components
5. Click "Execute Script" to run your script

## Security Considerations

- The application requires appropriate permissions to inject into other processes
- Memory protection features help prevent unauthorized modifications
- All memory operations are performed with proper error handling

## License

This project is licensed under the MIT License - see the LICENSE file for details. 