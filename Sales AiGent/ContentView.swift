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
    
    var body: some View {
        VStack(spacing: 20) {
            // Transcription Display
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !transcribedText.isEmpty {
                        Text("Transcription:")
                            .font(.headline)
                        Text(transcribedText)
                            .padding()
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(10)
                    }
                    
                    if !aiResponse.isEmpty {
                        Text("AI Response:")
                            .font(.headline)
                        Text(aiResponse)
                            .padding()
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            
            // Recording Controls
            Button(action: {
                isRecording.toggle()
                if isRecording {
                    startRecording()
                } else {
                    stopRecording()
                }
            }) {
                HStack {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 44))
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                }
                .foregroundColor(isRecording ? .red : .blue)
                .padding()
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(15)
            }
        }
        .padding()
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
        // Here we would send the transcribed text to OpenAI
        // and update aiResponse with the response
    }
}

#Preview {
    ContentView()
}
