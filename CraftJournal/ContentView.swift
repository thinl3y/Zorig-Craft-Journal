import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CraftEntry.date, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<CraftEntry>

    @State private var showingAddEntry = false
    @State private var searchText = ""                          // Choice 1
    @AppStorage("sortNewestFirst") private var sortNewestFirst = true   // Choice 2

    // Entries after searching and sorting
    private var displayedEntries: [CraftEntry] {
        let filtered = entries.filter { entry in
            searchText.isEmpty || (entry.title ?? "").localizedCaseInsensitiveContains(searchText)
        }
        return filtered.sorted { a, b in
            let dateA = a.date ?? .distantPast
            let dateB = b.date ?? .distantPast
            return sortNewestFirst ? dateA > dateB : dateA < dateB
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !displayedEntries.isEmpty {
                    Section {
                        ForEach(displayedEntries) { entry in
                            NavigationLink {
                                EntryDetailView(entry: entry)
                            } label: {
                                EntryRow(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    } header: {
                        Text("\(entries.count) \(entries.count == 1 ? "entry" : "entries")")
                    }
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries Yet",
                        systemImage: "camera",
                        description: Text("Tap + to photograph your first craft item.")
                    )
                } else if displayedEntries.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("Craft Journal")
            .searchable(text: $searchText, prompt: "Search by title")     // Choice 1
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {                   // Choice 2
                    Menu {
                        Picker("Sort", selection: $sortNewestFirst) {
                            Text("Newest first").tag(true)
                            Text("Oldest first").tag(false)
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        // offsets refer to the displayed (filtered and sorted) list
        offsets.map { displayedEntries[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print("Could not delete: \(error)")
        }
    }
}

struct EntryRow: View {
    @ObservedObject var entry: CraftEntry

    var body: some View {
        HStack {
            if let data = entry.photo, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "photo")
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading) {
                Text(entry.title ?? "Untitled")
                    .font(.headline)
                Text(entry.craftType ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let location = entry.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
