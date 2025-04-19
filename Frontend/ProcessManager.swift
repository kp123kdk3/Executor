import Foundation

class ProcessManager: ObservableObject {
    private let injector = ProcessInjector()
    @Published var processList: [(pid: Int32, name: String)] = []
    @Published var statusMessage = ""
    
    func refreshProcessList() {
        // Get list of all running processes
        let ws = NSWorkspace.shared
        processList = ws.runningApplications
            .filter { app in
                // Filter for Roblox processes
                let name = app.localizedName ?? ""
                return name.contains("Roblox") || name.contains("roblox")
            }
            .map { app in
                return (pid: app.processIdentifier, name: app.localizedName ?? "Unknown")
            }
    }
    
    func injectLibrary(pid: Int32) -> Bool {
        guard let libraryPath = Bundle.main.path(forResource: "libExecutorCore", ofType: "dylib") else {
            statusMessage = "Error: Could not find library"
            return false
        }
        
        // Check if the process is Roblox
        if let process = processList.first(where: { $0.pid == pid }),
           !process.name.lowercased().contains("roblox") {
            statusMessage = "Error: Can only inject into Roblox processes"
            return false
        }
        
        let success = injector.injectLibrary(libraryPath, intoProcess: pid)
        statusMessage = success ? "Library injected successfully" : "Failed to inject library"
        return success
    }
    
    func executeScript(_ script: String, inProcess pid: Int32) {
        // Add Roblox-specific script execution
        let robloxScript = """
            -- Roblox script wrapper
            local success, err = pcall(function()
                \(script)
            end)
            if not success then
                print("Script error:", err)
            end
        """
        
        do {
            try ScriptEngine().executeScript(robloxScript)
            statusMessage = "Script executed successfully"
        } catch {
            statusMessage = "Error executing script: \(error.localizedDescription)"
        }
    }
} 