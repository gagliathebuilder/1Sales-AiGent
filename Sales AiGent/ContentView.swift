//
//  ContentView.swift
//  Sales AiGent
//
//  Created by Christopher Gaglia on 1/21/25.
//

import SwiftUI
import Speech
import AVFoundation
import Alamofire

struct ContentView: View {
    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var aiResponse = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    var body: some View {
        VStack {
            Text("SpeechAI")
                .font(.largeTitle)
                .padding()
            
            ScrollView {
                Text(transcribedText)
                    .padding()
                
                Text(aiResponse)
                    .padding()
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                self.isRecording ? self.stopRecording() : self.startRecording()
            }) {
                Text(isRecording ? "Stop Listening" : "Start Listening")
                    .padding()
                    .background(isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            self.requestSpeechAuthorization()
        }
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Handle authorization status
        }
    }
    
    private func startRecording() {
        // Ensure previous tasks are canceled
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure the audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session properties weren't set because of an error.")
        }

        // Initialize the recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true

        // Start the audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine couldn't start because of an error.")
        }

        // Start the recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.sendToOpenAI(transcription: self.transcribedText)
            }
        })
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
    
    private func sendToOpenAI(transcription: String) {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            print("API Key not found in environment variables")
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        
        let parameters: [String: Any] = [
            "model": "text-davinci-003",
            "prompt": transcription,
            "max_tokens": 150
        ]
        
        AF.request("https://api.openai.com/v1/completions", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseDecodable(of: OpenAIResponse.self) { response in
            switch response.result {
            case .success(let openAIResponse):
                if let text = openAIResponse.choices.first?.text {
                    DispatchQueue.main.async {
                        self.aiResponse = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}

// Define a struct to match the expected response from OpenAI
struct OpenAIResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let text: String
    }
}

#Preview {
    ContentView()
}
