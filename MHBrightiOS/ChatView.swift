import SwiftUI

struct ChatView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = false
    @State private var isSending = false
    @State private var errorMessage = ""
    @State private var showClearConfirmation = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading chat...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if messages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "message")
                        .font(.largeTitle)

                    Text("Ask a health question")
                        .font(.headline)

                    Text("Your AI assistant can answer general health-related questions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) {
                        scrollToBottom(proxy: proxy)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }

            HStack {
                TextField("Type a message...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .disabled(isSending || newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Health Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Clear") {
                showClearConfirmation = true
            }
            .disabled(messages.isEmpty)
        }
        .alert("Clear Conversation?", isPresented: $showClearConfirmation) {
            Button("Clear", role: .destructive) {
                Task {
                    await clearChat()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all chat messages.")
        }
        .task {
            await loadMessages()
        }
    }

    private func loadMessages() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            messages = try await APIClient.shared.fetchChatMessages(token: token)
        } catch {
            errorMessage = "Could not load chat messages."
            print(error)
        }

        isLoading = false
    }

    private func sendMessage() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedMessage.isEmpty else {
            return
        }

        isSending = true
        errorMessage = ""
        newMessage = ""

        do {
            messages = try await APIClient.shared.sendChatMessage(
                message: trimmedMessage,
                token: token
            )
        } catch {
            errorMessage = "Could not send message."
            print(error)
        }

        isSending = false
    }

    private func clearChat() async {
        guard let token = authManager.token else {
            errorMessage = "Missing login token."
            return
        }

        errorMessage = ""

        do {
            try await APIClient.shared.clearChatMessages(token: token)
            messages = []
        } catch {
            errorMessage = "Could not clear conversation."
            print(error)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = messages.last else { return }

        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatView()
            .environmentObject(AuthManager())
    }
}
