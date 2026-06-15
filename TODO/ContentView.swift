import SwiftUI

#if os(macOS)
import AppKit
#endif

// 1. Model danych dla zadania
struct TodoItem: Identifiable, Codable, Equatable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
}

struct ContentView: View {
    private let todosKey = "SavedTodos"
    
    @State private var todos: [TodoItem] = []
    @State private var newTodoTitle: String = ""
    @State private var hoveredTodoID: UUID? = nil
    @State private var isPinned: Bool = false
    @State private var isShowingSettings: Bool = false

    enum AppStyle: String, CaseIterable, Identifiable, Codable {
        case system
        case light
        case dark
        case glass
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            case .glass: return "Glass"
            }
        }
    }

    private let styleKey = "SelectedAppStyle"
    @State private var selectedStyle: AppStyle = .system
    
    init() {
        if let data = UserDefaults.standard.data(forKey: todosKey),
           let saved = try? JSONDecoder().decode([TodoItem].self, from: data) {
            _todos = State(initialValue: saved)
        } else {
            _todos = State(initialValue: [
                TodoItem(title: "Buy a milk"),
                TodoItem(title: "Do workout")
            ])
        }
        if let raw = UserDefaults.standard.string(forKey: styleKey),
           let style = AppStyle(rawValue: raw) {
            _selectedStyle = State(initialValue: style)
        }
    }
    
    var body: some View {
        ZStack {
            Group {
                if selectedStyle == .glass {
                    Color.clear.background(.ultraThinMaterial)
                } else {
                    Color.clear
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                
                HStack {
                    CircleTextField(
                        text: $newTodoTitle,
                        placeholder: "New Task...",
                        onSubmit: addTodo
                    )
                }
                .padding(.horizontal)
                
                List {
                    ForEach($todos) { $todo in
                        HStack {
                            Group {
                                if todo.isCompleted && hoveredTodoID == todo.id {
                                    Button(action: {
                                        withAnimation {
                                            if let index = todos.firstIndex(where: { $0.id == todo.id }) {
                                                todos.remove(at: index)
                                                saveTodos()
                                            }
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                    .buttonStyle(.borderless)
                                } else {
                                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(todo.isCompleted ? .green : .gray)
                                        .onTapGesture {
                                            withAnimation {
                                                todo.isCompleted.toggle()
                                                saveTodos()
                                            }
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .animation(.easeInOut(duration: 0.18), value: todo.isCompleted && hoveredTodoID == todo.id)

                            Text(todo.title)
                                .padding(8)
                                .strikethrough(todo.isCompleted)
                                .foregroundColor(todo.isCompleted ? .gray : .primary)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                todo.isCompleted.toggle()
                                saveTodos()
                            }
                        }
                        .contextMenu {
                            if todo.isCompleted {
                                Button("Oznacz jako niezrobione", systemImage: "checkmark.circle") {
                                    todo.isCompleted = false
                                    saveTodos()
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .onHover { hovering in
                            hoveredTodoID = hovering ? todo.id : nil
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .padding(.top)
        }
        .preferredColorScheme({
            switch selectedStyle {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            case .glass: return nil
            }
        }())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    togglePin()
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                }
                .help(isPinned ? "Odepnij okno" : "Przypnij okno")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openSettingsWindow()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Ustawienia")
            }
        }
        .frame(minWidth: 300, minHeight: 400)
        .onChange(of: selectedStyle) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: styleKey)
            #if os(macOS)
            applyGlassWindowIfNeeded()
            #endif
        }
        .onAppear {
            #if os(macOS)
            applyGlassWindowIfNeeded()
            #endif
        }
    }
    
    // Funkcja dodawania
    private func addTodo() {
        let trimmed = newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        todos.append(TodoItem(title: trimmed))
        saveTodos()
        newTodoTitle = ""
    }
    
    private func saveTodos() {
        if let data = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(data, forKey: todosKey)
        }
    }
    
    #if os(macOS)
    private func applyGlassWindowIfNeeded() {
        let makeBlurView: () -> NSVisualEffectView = {
            let v = NSVisualEffectView()
            v.material = .underWindowBackground
            v.blendingMode = .behindWindow
            v.state = .active
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }

        for window in NSApp.windows {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true

            // Skip the Settings window; it should remain system styled
            if window.identifier?.rawValue == "SettingsWindow" || window.title == "Ustawienia" {
                // Also make sure it uses system defaults when Glass is active
                window.isOpaque = true
                window.backgroundColor = NSColor.windowBackgroundColor
                window.styleMask.remove(.fullSizeContentView)
                window.hasShadow = true
                if let contentView = window.contentView {
                    contentView.subviews
                        .filter { $0 is NSVisualEffectView }
                        .forEach { $0.removeFromSuperview() }
                    contentView.wantsLayer = false
                }
                continue
            }

            if selectedStyle == .glass {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.styleMask.insert(.fullSizeContentView)
                window.hasShadow = true

                if let contentView = window.contentView {
                    // Ensure the contentView is clear to let vibrancy show
                    contentView.wantsLayer = true
                    contentView.layer?.backgroundColor = NSColor.clear.cgColor

                    // Insert a visual effect view behind SwiftUI content to guarantee subtle blur
                    let existingVEV = contentView.subviews.first { $0 is NSVisualEffectView }
                    if existingVEV == nil {
                        let vev = makeBlurView()
                        contentView.addSubview(vev, positioned: .below, relativeTo: contentView.subviews.first)
                        NSLayoutConstraint.activate([
                            vev.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                            vev.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                            vev.topAnchor.constraint(equalTo: contentView.topAnchor),
                            vev.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                        ])
                    }
                }
            } else {
                // Revert to default appearance for non-glass styles
                window.isOpaque = true
                window.backgroundColor = NSColor.windowBackgroundColor
                window.styleMask.remove(.fullSizeContentView)
                window.hasShadow = true

                if let contentView = window.contentView {
                    // Remove any inserted visual effect view we added
                    contentView.subviews
                        .filter { $0 is NSVisualEffectView }
                        .forEach { $0.removeFromSuperview() }

                    contentView.wantsLayer = false
                }
            }
        }
    }
    #endif

    #if os(macOS)
    private func togglePin() {
        isPinned.toggle()
        // Attempt to set the window level to keep the window on top when pinned
        if let window = NSApp.keyWindow ?? NSApp.windows.first {
            window.level = isPinned ? .floating : .normal
        }
    }
    #else
    private func togglePin() {
        // On iOS/iPadOS there is no concept of pinning a window always-on-top.
        // We simply toggle the state for UI feedback.
        isPinned.toggle()
    }
    #endif

    #if os(macOS)
    private func openSettingsWindow() {
        // Create a new window for settings
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Ustawienia"
        window.identifier = NSUserInterfaceItemIdentifier("SettingsWindow")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView(selectedStyle: $selectedStyle))
        window.makeKeyAndOrderFront(nil)
    }
    #else
    private func openSettingsWindow() {
        // On iOS/iPadOS/tvOS: fall back to sheet presentation
        isShowingSettings = true
    }
    #endif
}




struct SettingsView: View {
    @Binding var selectedStyle: ContentView.AppStyle
    private let styleKey = "SelectedAppStyle"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title3)
                .bold()

            Picker("Style", selection: $selectedStyle) {
                ForEach(ContentView.AppStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedStyle) { _, newValue in
                UserDefaults.standard.set(newValue.rawValue, forKey: styleKey)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

