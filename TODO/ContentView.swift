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
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "Systemowy"
            case .light: return "Jasny"
            case .dark: return "Ciemny"
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
                TodoItem(title: "Kupić mleko"),
                TodoItem(title: "Zrobić trening")
            ])
        }
        if let raw = UserDefaults.standard.string(forKey: styleKey),
           let style = AppStyle(rawValue: raw) {
            _selectedStyle = State(initialValue: style)
        }
    }
    
    var body: some View {
        ZStack {
            Color.clear.background(.ultraThinMaterial)

            VStack(spacing: 12) {
                
                HStack {
                    TextField("New Task...", text: $newTodoTitle)
                        .onSubmit { addTodo() }
                    
                    CircleButton(systemImage: "plus", size: 30, action: addTodo)
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
