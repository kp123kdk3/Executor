import Foundation

class ScriptEngine {
    private var engine: OpaquePointer?
    
    init() {
        engine = createLuaEngine()
    }
    
    deinit {
        if let engine = engine {
            destroyLuaEngine(engine)
        }
    }
    
    var isInitialized: Bool {
        guard let engine = engine else { return false }
        return isEngineInitialized(engine)
    }
    
    // Function to send a script to the engine via IPC
    func executeScript(_ script: String) throws {
        guard let scriptData = script.data(using: .utf8) else {
            throw ScriptError.encodingError
        }
        
        // Open the named pipe for writing
        let pipePath = "/tmp/lua_script_pipe"
        guard let fileHandle = FileHandle(forWritingAtPath: pipePath) else {
            throw ScriptError.pipeError
        }
        
        defer {
            try? fileHandle.close()
        }
        
        // Write the script size followed by the script content
        let size = UInt32(scriptData.count)
        let sizeData = withUnsafeBytes(of: size) { Data($0) }
        
        fileHandle.write(sizeData)
        fileHandle.write(scriptData)
    }
}

enum ScriptError: Error {
    case encodingError
    case pipeError
} 