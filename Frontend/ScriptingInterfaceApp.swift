import SwiftUI
import ExecutorCore

// MARK: - Theme
struct Theme {
    static let background = Color(hex: "1E1E1E")
    static let secondaryBackground = Color(hex: "252526")
    static let accent = Color(hex: "007AFF")
    static let text = Color(hex: "CCCCCC")
    static let secondaryText = Color(hex: "8E8E93")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom Button Style
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ProcessInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let pid: Int32
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ProcessInfo, rhs: ProcessInfo) -> Bool {
        return lhs.id == rhs.id
    }
}

class ProcessViewModel: ObservableObject {
    @Published var processes: [ProcessInfo] = []
    @Published var statusMessage = ""
    
    func refreshProcesses() {
        processes = ProcessManager.runningProcesses().map { dict in
            let name = dict["name"] as! String
            let pid = (dict["pid"] as! NSNumber).int32Value
            return ProcessInfo(name: name, pid: pid)
        }
    }
    
    func injectLibrary(pid: Int32) {
        let success = ProcessManager.injectLibrary("dummy.dylib", intoPID: pid)
        statusMessage = success ? "Injection successful" : "Injection failed"
    }
}

struct ScriptEditor: View {
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: $text)
            .font(.custom("Menlo", size: 14))
            .foregroundColor(Theme.text)
            .scrollContentBackground(.hidden)
            .background(Theme.secondaryBackground)
            .cornerRadius(12)
            .padding(1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
            )
    }
}

struct ProcessSelectorView: View {
    @Binding var selectedProcess: ProcessInfo?
    @ObservedObject var viewModel: ProcessViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(viewModel.processes) { process in
                    Button(action: { selectedProcess = process }) {
                        Text("\(process.name) (\(process.pid))")
                    }
                }
            } label: {
                HStack {
                    Text(selectedProcess?.name ?? "Select Process")
                        .foregroundColor(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(Theme.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.secondaryBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                )
            }
            .frame(width: 250)
            
            Button(action: { viewModel.refreshProcesses() }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.white)
            }
            .buttonStyle(ModernButtonStyle(color: Theme.accent))
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ProcessViewModel()
    @State private var selectedProcess: ProcessInfo?
    @State private var script = ""
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProcessSelectorView(selectedProcess: $selectedProcess, viewModel: viewModel)
                    .padding(.horizontal)
                
                ScriptEditor(text: $script)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                HStack(spacing: 12) {
                    Button("Inject") {
                        if let process = selectedProcess {
                            viewModel.injectLibrary(pid: process.pid)
                        }
                    }
                    .buttonStyle(ModernButtonStyle(color: Theme.accent))
                    .disabled(selectedProcess == nil)
                    
                    Button("Execute") {
                        // Execute functionality will be added later
                    }
                    .buttonStyle(ModernButtonStyle(color: Color(hex: "34C759")))
                    .disabled(script.isEmpty)
                }
                
                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .foregroundColor(Theme.secondaryText)
                        .font(.system(.caption))
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.refreshProcesses()
        }
    }
}

@main
struct ScriptingInterfaceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
    }
} 