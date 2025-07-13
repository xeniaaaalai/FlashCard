//
//  ContentView.swift
//  FlashCard
//
//  Created by Xenia Lai on 2025/7/6.
//

import SwiftUI

struct Word: Identifiable, Codable {
    let id = UUID()
    let english: String
    let chinese: String
}

class WordStore: ObservableObject {
    @Published var words: [Word] = []
    
    func add(word: Word) {
        words.append(word)
        save()
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
    @State private var showQuiz = false
    
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
                
                Text("中文翻譯：\(chineseResult)")
                    .padding()
                
                Button("儲存") {
                    if !englishInput.isEmpty && !chineseResult.isEmpty {
                        let word = Word(english: englishInput, chinese: chineseResult)
                        store.add(word: word)
                        englishInput = ""
                        chineseResult = ""
                    }
                }
                .padding()
                
                Button("抽考") {
                    showQuiz = true
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
            .onAppear {
                store.load()
            }
            .sheet(isPresented: $showQuiz) {
                QuizView(words: store.words)
            }
        }
    }
    
    func queryWord() {
        // 這裡應該連接 API 查詢英文單字的中文翻譯
        // 範例: 使用假資料
        chineseResult = "（這裡顯示查詢結果，實際應由API取得）"
        // 例如: callAPI(englishInput) { result in chineseResult = result }
    }
}

struct QuizView: View {
    let words: [Word]
    @State private var currentIndex = 0
    @State private var userAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false
    
    var body: some View {
        VStack(spacing: 20) {
            if words.isEmpty {
                Text("尚未儲存任何單字")
            } else {
                Text("請輸入「\(words[currentIndex].english)」的中文翻譯")
                TextField("你的答案", text: $userAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("提交") {
                    isCorrect = userAnswer == words[currentIndex].chinese
                    showResult = true
                }
                .padding()
                
                if showResult {
                    Text(isCorrect ? "答對了！" : "答錯了，正確答案是：\(words[currentIndex].chinese)")
                        .foregroundColor(isCorrect ? .green : .red)
                    Button("下一題") {
                        userAnswer = ""
                        showResult = false
                        currentIndex = (currentIndex + 1) % words.count
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
