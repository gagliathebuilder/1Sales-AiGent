//
//  ContentView.swift
//  Sales AiGent
//
//  Created by Christopher Gaglia on 1/21/25.
//

import SwiftUI
import Speech
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var transcribedText = ""
    @State private var isRecording = false
    @State private var aiResponse = ""
    @StateObject private var openAIService = OpenAIService()
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Header
                Text("Sales AiGent")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top)
                
                // Transcription Display
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !transcribedText.isEmpty {
                            TranscriptionCard(title: "Your Speech", content: transcribedText)
                        }
                        
                        if !aiResponse.isEmpty {
                            TranscriptionCard(title: "AI Coach Feedback", content: aiResponse)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Recording Button
                Button(action: {
                    isRecording.toggle()
                    if isRecording {
                        startRecording()
                    } else {
                        stopRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 80, height: 80)
                            .shadow(radius: 5)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .overlay(
            Group {
                if isProcessing {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing your sales approach...")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                }
            }
        )
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            requestSpeechPermission()
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition authorization denied")
                case .restricted:
                    print("Speech recognition restricted")
                case .notDetermined:
                    print("Speech recognition not determined")
                @unknown default:
                    print("Speech recognition unknown status")
                }
            }
        }
    }
    
    private func startRecording() {
        speechRecognizer.startRecording { result in
            switch result {
            case .success(let text):
                transcribedText = text
            case .failure(let error):
                print("Recording error: \(error.localizedDescription)")
            }
        }
    }
    
    private func stopRecording() {
        speechRecognizer.stopRecording()
        
        // Only proceed if we have transcribed text
        guard !transcribedText.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            do {
                let response = try await openAIService.generateSalesCoachingResponse(for: transcribedText)
                await MainActor.run {
                    aiResponse = response
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
}

// Custom card view for transcriptions
struct TranscriptionCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if title == "AI Coach Feedback" {
                    Button(action: {
                        UIPasteboard.general.string = content
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
        }
        .padding(.vertical, 8)
    }
}

// Custom color extension for consistent theming
extension Color {
    static let darkBackground = Color(uiColor: .systemBackground)
    static let cardBackground = Color(uiColor: .secondarySystemBackground)
    static let accentBlue = Color.blue
}

#Preview {
    ContentView()
}
