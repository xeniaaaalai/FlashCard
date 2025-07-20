//
//  ContentView.swift
//  FlashCard
//
//  Created by Xenia Lai on 2025/7/6.
//

import SwiftUI
import Foundation

struct Word: Identifiable, Codable, Equatable {
    let id = UUID()
    let english: String
    let chinese: String
}

class WordStore: ObservableObject {
    @Published var words: [Word] = []
    
    init() {
        load()
    }
    
    func add(word: Word) {
        if !words.contains(where: { $0.english.lowercased() == word.english.lowercased() }) {
            words.append(word)
            save()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(data, forKey: "SavedWords")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "SavedWords"),
           let saved = try? JSONDecoder().decode([Word].self, from: data) {
            words = saved
        }
    }
}

struct ContentView: View {
    @StateObject var store = WordStore()
    @State private var englishInput = ""
    @State private var chineseResult = ""
    @State private var showSavePrompt = false
    @State private var errorMessage = ""
    @State private var showFlashCard = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("輸入英文單字", text: $englishInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("查詢") {
                    queryWord()
                }
                .padding()
                
                if !chineseResult.isEmpty {
                    Text("中文翻譯：\(chineseResult)")
                        .padding()
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button("單字卡抽考") {
                    showFlashCard = true
                }
                .padding()
                
                List(store.words) { word in
                    VStack(alignment: .leading) {
                        Text(word.english)
                        Text(word.chinese).foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("背單字 App")
            .sheet(isPresented: $showSavePrompt) {
                SavePromptView(word: Word(english: englishInput, chinese: chineseResult), store: store)
            }
            .sheet(isPresented: $showFlashCard) {
                FlashCardView(words: store.words)
            }
        }
    }
    
    func queryWord() {
        errorMessage = ""
        chineseResult = ""
        guard !englishInput.isEmpty else {
            errorMessage = "請輸入英文單字"
            return
        }
        // 串接 LibreTranslate API
        let url = URL(string: "https://libretranslate.com/translate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let params = [
            "q": englishInput,
            "source": "en",
            "target": "zh",
            "format": "text"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "查詢失敗: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let translated = json["translatedText"] as? String else {
                DispatchQueue.main.async {
                    errorMessage = "查無翻譯結果"
                }
                return
            }
            DispatchQueue.main.async {
                chineseResult = translated
                showSavePrompt = true
            }
        }.resume()
    }
}

struct SavePromptView: View {
    let word: Word
    @ObservedObject var store: WordStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("是否儲存？")
            Text("\(word.english) - \(word.chinese)")
            Button("儲存") {
                store.add(word: word)
                dismiss()
            }
            Button("取消") {
                dismiss()
            }
        }
        .padding()
    }
}

struct FlashCardView: View {
    let words: [Word]
    @State private var currentIndex: Int = 0
    @State private var showChinese = false
    
    var body: some View {
        VStack(spacing: 30) {
            if words.isEmpty {
                Text("尚未儲存任何單字")
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 200)
                        .shadow(radius: 5)
                    
                    VStack {
                        Text(showChinese ? words[currentIndex].chinese : words[currentIndex].english)
                            .font(.largeTitle)
                            .bold()
                            .padding()
                        Button(showChinese ? "顯示英文" : "顯示中文") {
                            withAnimation {
                                showChinese.toggle()
                            }
                        }
                    }
                }
                Button("抽下一張") {
                    var newIndex: Int
                    repeat {
                        newIndex = Int.random(in: 0..<words.count)
                    } while newIndex == currentIndex && words.count > 1
                    currentIndex = newIndex
                    showChinese = false
                }
            }
        }
        .padding()
        .onAppear {
            if !words.isEmpty {
                currentIndex = Int.random(in: 0..<words.count)
            }
        }
    }
}

#Preview {
    ContentView()
}
