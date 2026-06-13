import SwiftUI

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
    }
    
    var body: some View {
        ZStack {
            Color.clear.background(.ultraThinMaterial)

            VStack(spacing: 12) {
                HStack {
                    Button(action: { print("Lewy przycisk nacisniety") }) {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Circle().fill(Color.red))//do zmainy
                    }
                    Spacer()
                    Button(action: { print("Prawy przycisk nacisniety") }) {
                        Image(systemName: "star")
                            .foregroundColor(.yellow)
                            .padding(10)
                            .background(Circle().fill(Color.green))//do zmiany
                    }
                }
                .padding(.horizontal)
                
                HStack {
                    TextField("New Task...", text: $newTodoTitle)
                        .onSubmit { addTodo() }
                    
                    Button(action: addTodo) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glass)
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
}

#Preview {
    ContentView()
}
