import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import UIKit
import AVFoundation

struct NoteDetailView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var audio = NoteAudioController()
    @State private var showingMoveProject = false
    @State private var showingLeaveAudioAlert = false

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var fullScreenImage: NoteImage?
    @State private var showingCamera = false
    @State private var showingDocumentImporter = false
    @State private var previewURL: URL?
    @State private var showingCameraUnavailableAlert = false

    var body: some View {
        noteForm
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if audio.isRecording || audio.draftURL != nil {
                            audio.stopRecording()
                            showingLeaveAudioAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(audio.isRecording || audio.draftURL != nil || audio.isRequestingPermission)
            .navigationBarBackButtonHidden(audio.isRecording || audio.draftURL != nil)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { audio.suspend() }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in
                audio.suspend()
            }
            .onDisappear { audio.close() }
            .alert("Unsaved recording", isPresented: $showingLeaveAudioAlert) {
                Button("Keep editing", role: .cancel) {}
                Button("Discard and leave", role: .destructive) {
                    audio.discardDraft()
                    dismiss()
                }
            } message: {
                Text("Save your recording in the Audio section before leaving, or discard it.")
            }
            .alert("Audio", isPresented: Binding(
                get: { audio.errorMessage != nil },
                set: { if !$0 { audio.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { audio.errorMessage = nil }
            } message: {
                Text(audio.errorMessage ?? "")
            }
            .onChange(of: selectedPhotoItems) { _, newItems in
                Task { await addImages(from: newItems) }
            }
            .fullScreenCover(item: $fullScreenImage) { image in
                ImageViewerView(noteImage: image)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraCaptureView(
                    onCapture: { image in
                        addCapturedImage(image)
                        showingCamera = false
                    },
                    onCancel: { showingCamera = false }
                )
                .ignoresSafeArea()
            }
            .fileImporter(isPresented: $showingDocumentImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                handleDocumentImport(result)
            }
            .alert("Camera Unavailable", isPresented: $showingCameraUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device doesn't have a camera available.")
            }
            .sheet(isPresented: $showingMoveProject) {
                MoveNoteView(note: note)
            }
            .sheet(isPresented: isShowingPreview) {
                if let previewURL {
                    DocumentPreviewView(url: previewURL)
                }
            }
    }

    private var noteForm: some View {
        Form {
                Section {
                    TextField("Title", text: $note.title)
                        .font(.title3.bold())
                        .fontDesign(.rounded)
                    TextField("Note", text: $note.body, axis: .vertical)
                        .lineLimit(5...20)
                }

                Section {
                    Button(action: toggleComplete) {
                        HStack {
                            Image(systemName: note.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(note.isDone ? Color.coral : Color.secondary)
                            Text(note.isDone ? "Completed" : "Mark Complete")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                    Button {
                        note.isPinned.toggle()
                    } label: {
                        HStack {
                            Image(systemName: note.isPinned ? "pin.fill" : "pin")
                                .foregroundStyle(note.isPinned ? Color.coral : Color.secondary)
                            Text(note.isPinned ? "Pinned" : "Pin to Home")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }

                Section("Project") {
                    Button {
                        audio.stopPlayback()
                        showingMoveProject = true
                    } label: {
                        HStack {
                            Label(note.project?.name ?? "No project", systemImage: note.project?.icon ?? "folder")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("Move")
                                .foregroundStyle(Color.coral)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Move to Project. Current project: \(note.project?.name ?? "None")")
                    .disabled(audio.isRecording || audio.draftURL != nil || audio.isRequestingPermission)
                }

                NoteAudioSection(note: note, audio: audio)

                Section("Photos") {
                    imageGrid
                    HStack {
                        PhotosPicker(selection: $selectedPhotoItems, matching: .images) {
                            Label("Library", systemImage: "photo.on.rectangle.angled")
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showingCamera = true
                            } else {
                                showingCameraUnavailableAlert = true
                            }
                        } label: {
                            Label("Camera", systemImage: "camera.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Documents") {
                    ForEach(note.sortedDocuments) { document in
                        DocumentRowView(document: document)
                            .contentShape(Rectangle())
                            .onTapGesture { previewURL = document.writeToTemporaryURL() }
                    }
                    .onDelete(perform: deleteDocuments)

                    Button {
                        showingDocumentImporter = true
                    } label: {
                        Label("Add Document", systemImage: "doc.badge.plus")
                    }
                }

                Section {
                    LabeledContent("Created", value: note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    if let completedAt = note.completedAt {
                        LabeledContent("Completed", value: completedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
    }

    private var isShowingPreview: Binding<Bool> {
        Binding(get: { previewURL != nil }, set: { if !$0 { previewURL = nil } })
    }

    private var imageGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 84, maximum: 104), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(note.sortedImages) { image in
                if let uiImage = UIImage(data: image.data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                        .onTapGesture { fullScreenImage = image }
                        .overlay(alignment: .topTrailing) {
                            Button {
                                deleteImage(image)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white, .black.opacity(0.65))
                                    .frame(width: 36, height: 36)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .offset(x: 8, y: -8)
                        }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleComplete() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            note.toggleComplete()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func addImages(from items: [PhotosPickerItem]) async {
        var nextOrder = (note.images.map(\.sortOrder).max() ?? -1) + 1
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let image = NoteImage(data: data, sortOrder: nextOrder)
                image.note = note
                modelContext.insert(image)
                note.images.append(image)
                nextOrder += 1
            }
        }
        selectedPhotoItems = []
    }

    private func addCapturedImage(_ uiImage: UIImage) {
        guard let data = uiImage.jpegData(compressionQuality: 0.9) else { return }
        let nextOrder = (note.images.map(\.sortOrder).max() ?? -1) + 1
        let image = NoteImage(data: data, sortOrder: nextOrder)
        image.note = note
        modelContext.insert(image)
        note.images.append(image)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func deleteImage(_ image: NoteImage) {
        note.images.removeAll { $0.persistentModelID == image.persistentModelID }
        modelContext.delete(image)
    }

    /// `.item` lets the system "Browse" picker surface every installed Files
    /// provider — iCloud Drive, On My iPhone, and Google Drive if its app is
    /// installed — without this app talking to any cloud API directly. The
    /// file's bytes are copied in, same as photos, so the note stays
    /// self-contained even if the original Drive file later moves or is
    /// deleted.
    private func handleDocumentImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        var nextOrder = (note.documents.map(\.sortOrder).max() ?? -1) + 1
        for url in urls {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { continue }
            let document = NoteDocument(
                data: data,
                fileName: url.deletingPathExtension().lastPathComponent,
                fileExtension: url.pathExtension,
                sortOrder: nextOrder
            )
            document.note = note
            modelContext.insert(document)
            note.documents.append(document)
            nextOrder += 1
        }
    }

    private func deleteDocuments(at offsets: IndexSet) {
        let documents = note.sortedDocuments
        for index in offsets {
            let document = documents[index]
            note.documents.removeAll { $0.persistentModelID == document.persistentModelID }
            modelContext.delete(document)
        }
    }
}
