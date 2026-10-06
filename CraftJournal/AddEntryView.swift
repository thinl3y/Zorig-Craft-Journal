import SwiftUI
import CoreData
import PhotosUI

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // nil = creating a new entry, otherwise we are editing this entry
    let entryToEdit: CraftEntry?

    @State private var title: String
    @State private var craftType: String
    @State private var location: String
    @State private var notes: String
    @State private var image: UIImage?
    @State private var photoChanged = false
    @State private var showingCamera = false
    @State private var selectedItem: PhotosPickerItem?

    init(entryToEdit: CraftEntry? = nil) {
        self.entryToEdit = entryToEdit
        _title = State(initialValue: entryToEdit?.title ?? "")
        _craftType = State(initialValue: entryToEdit?.craftType ?? crafts[0])
        _location = State(initialValue: entryToEdit?.location ?? "")
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        if let data = entryToEdit?.photo {
            _image = State(initialValue: UIImage(data: data))
        } else {
            _image = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Craft", selection: $craftType) {
                    ForEach(crafts, id: \.self) { craft in
                        Text(craft)
                    }
                }
                TextField("Location found", text: $location)
                TextField("Notes", text: $notes, axis: .vertical)

                Section("Photo") {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                    }
                    Button("Take Photo") {
                        showingCamera = true
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                    PhotosPicker("Choose from Library", selection: $selectedItem, matching: .images)
                }
            }
            .navigationTitle(entryToEdit == nil ? "New Entry" : "Edit Entry")
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $image)
                    .ignoresSafeArea()
            }
            .onChange(of: image) { _, _ in
                photoChanged = true
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveEntry() {
        let entry: CraftEntry
        if let existing = entryToEdit {
            entry = existing                    // update the SAME object
        } else {
            entry = CraftEntry(context: viewContext)   // create a NEW object
            entry.id = UUID()
            entry.date = Date()
        }
        entry.title = title
        entry.craftType = craftType
        entry.location = location
        entry.notes = notes
        if entryToEdit == nil || photoChanged {
            entry.photo = image?.jpegData(compressionQuality: 0.7)
        }
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Could not save: \(error)")
        }
    }
}
