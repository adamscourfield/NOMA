import SwiftUI
import SwiftData
import AVFoundation

struct NoteAudioSection: View {
    @Bindable var note: Note
    @ObservedObject var audio: NoteAudioController
    @Environment(\.modelContext) private var modelContext
    @State private var documentToDelete: NoteDocument?

    var body: some View {
        Section {
            ForEach(note.sortedAudio) { document in
                AudioRecordingRow(document: document, audio: audio)
                    .disabled(audio.isRecording || audio.draftURL != nil || audio.isRequestingPermission)
                    .swipeActions {
                        Button(role: .destructive) { documentToDelete = document } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            if audio.isRecording || audio.draftURL != nil {
                recorder
            } else {
                Button {
                    Task { await audio.startRecording() }
                } label: {
                    Label(audio.isRequestingPermission ? "Waiting for Microphone…" : "Record audio", systemImage: "mic")
                }
                .disabled(audio.isRequestingPermission)
            }
        } header: {
            Text("Audio")
        } footer: {
            Text("Record a thought, a reminder, or a conversation. Saved only in this note.")
        }
        .alert("Delete recording?", isPresented: Binding(
            get: { documentToDelete != nil },
            set: { if !$0 { documentToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                guard let document = documentToDelete else { return }
                if audio.playingID == document.persistentModelID { audio.stopPlayback() }
                note.documents.removeAll { $0.persistentModelID == document.persistentModelID }
                modelContext.delete(document)
                documentToDelete = nil
            }
            Button("Cancel", role: .cancel) { documentToDelete = nil }
        } message: {
            Text("This removes the audio from this note.")
        }
    }

    private var recorder: some View {
        VStack(spacing: 16) {
            HStack {
                Label(audio.isRecording ? "Recording" : "Ready to save", systemImage: audio.isRecording ? "record.circle" : "waveform")
                    .foregroundStyle(Color.coral)
                Spacer()
                Text(NoteAudioController.timeString(audio.recordingDuration))
                    .font(.title2.monospacedDigit())
            }
            if audio.isRecording {
                HStack(spacing: 4) {
                    ForEach(0..<36, id: \.self) { index in
                        Capsule()
                            .fill(Color.coral)
                            .frame(height: 4 + audio.level * CGFloat(8 + (index * 13 % 24)))
                    }
                }
                .frame(height: 36)
                .animation(.easeOut(duration: 0.1), value: audio.level)
                .accessibilityHidden(true)
            }
            HStack {
                Button("Discard", role: .destructive) { audio.discardDraft() }
                    .buttonStyle(.borderless)
                Spacer()
                if audio.isRecording {
                    Button { audio.stopRecording() } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Save recording", action: saveRecording)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func saveRecording() {
        do {
            let data = try audio.draftData()
            let document = NoteDocument(
                data: data,
                fileName: "Recording \(Date.now.formatted(date: .abbreviated, time: .shortened))",
                fileExtension: "m4a",
                sortOrder: (note.documents.map(\.sortOrder).max() ?? -1) + 1
            )
            modelContext.insert(document)
            document.note = note
            do {
                try modelContext.save()
                audio.discardDraft()
            } catch {
                // Keep the draft so a failed disk write can be retried.
                note.documents.removeAll { $0.persistentModelID == document.persistentModelID }
                modelContext.delete(document)
                throw error
            }
        } catch {
            audio.errorMessage = "Couldn't save recording: \(error.localizedDescription)"
        }
    }
}

private struct AudioRecordingRow: View {
    @Bindable var document: NoteDocument
    @ObservedObject var audio: NoteAudioController
    @State private var duration: TimeInterval = 0

    private var isPlaying: Bool { audio.playingID == document.persistentModelID }

    var body: some View {
        HStack(spacing: 12) {
            Button { audio.togglePlayback(document) } label: {
                Image(systemName: isPlaying && audio.isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 44, height: 44)
                    .background(Color.coral.opacity(0.12), in: Circle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(isPlaying && audio.isPlaying ? "Pause recording" : "Play recording")
            VStack(alignment: .leading, spacing: 4) {
                TextField("Recording name", text: $document.fileName)
                    .font(.subheadline.weight(.medium))
                    .accessibilityLabel("Recording name")
                HStack {
                    if isPlaying {
                        Text("\(NoteAudioController.timeString(audio.playbackTime)) / \(NoteAudioController.timeString(audio.playbackDuration))")
                            .monospacedDigit()
                    } else {
                        Text(NoteAudioController.timeString(duration))
                            .monospacedDigit()
                    }
                    Text("·")
                    Text(document.createdAt, format: .dateTime.day().month(.abbreviated))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if isPlaying {
                    ProgressView(value: audio.playbackTime, total: max(1, audio.playbackDuration))
                        .tint(Color.coral)
                }
            }
        }
        .padding(.vertical, 4)
        .task { duration = (try? AVAudioPlayer(data: document.data).duration) ?? 0 }
    }
}
