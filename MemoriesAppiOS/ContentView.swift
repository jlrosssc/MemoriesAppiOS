import SwiftUI

struct ContentView: View {
    @AppStorage("serverURL") private var serverURL = ServerSettings.defaultServerURL
    @StateObject private var browserState = BrowserState()
    @State private var draftServerURL = ServerSettings.defaultServerURL
    @State private var selectedURL: URL?
    @State private var showingSettings = false
    @State private var validationMessage: String?

    private var baseURL: URL? {
        ServerSettings.normalizedServerURL(from: serverURL)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let targetURL = selectedURL ?? baseURL {
                    VStack(spacing: 0) {
                        progressView
                        MemoriesWebView(targetURL: targetURL, state: browserState)
                    }
                } else {
                    setupView
                }
            }
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        browserState.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!browserState.canGoBack)

                    Button {
                        browserState.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!browserState.canGoForward)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            navigate(to: "/")
                        } label: {
                            Label("Home", systemImage: "house")
                        }

                        Button {
                            navigate(to: "/media/new")
                        } label: {
                            Label("Add Media", systemImage: "plus.rectangle.on.folder")
                        }

                        Button {
                            navigate(to: "/needs-details")
                        } label: {
                            Label("Needs Details", systemImage: "tag")
                        }

                        Button {
                            navigate(to: "/guide")
                        } label: {
                            Label("Guide", systemImage: "book")
                        }

                        Button {
                            navigate(to: "/admin")
                        } label: {
                            Label("Admin", systemImage: "person.crop.circle.badge.gearshape")
                        }

                        Divider()

                        if let currentURL = browserState.currentURL {
                            ShareLink(item: currentURL) {
                                Label("Share Current Page", systemImage: "square.and.arrow.up")
                            }
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Label("Server Settings", systemImage: "server.rack")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    Button {
                        browserState.isLoading ? browserState.stopLoading() : browserState.reload()
                    } label: {
                        Image(systemName: browserState.isLoading ? "xmark" : "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                settingsView
            }
            .onAppear {
                draftServerURL = serverURL
                selectedURL = baseURL
            }
        }
    }

    private var progressView: some View {
        Group {
            if browserState.isLoading {
                ProgressView(value: browserState.estimatedProgress)
                    .progressViewStyle(.linear)
            } else {
                Divider()
            }
        }
        .frame(height: 2)
    }

    private var setupView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Connect to the Memories server.")
                .font(.title2.weight(.semibold))

            TextField("https://memories.example.com", text: $draftServerURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .textFieldStyle(.roundedBorder)

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                saveServerURL()
            } label: {
                Label("Connect", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("Memories Server") {
                    TextField("Server URL", text: $draftServerURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("Shortcuts") {
                    Button("Open Home") { saveAndNavigate(to: "/") }
                    Button("Open Add Media") { saveAndNavigate(to: "/media/new") }
                    Button("Open Needs Details") { saveAndNavigate(to: "/needs-details") }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        draftServerURL = serverURL
                        validationMessage = nil
                        showingSettings = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveServerURL()
                        showingSettings = false
                    }
                }
            }
        }
    }

    private func navigate(to path: String) {
        guard let baseURL else {
            showingSettings = true
            return
        }
        selectedURL = ServerSettings.appending(path: path, to: baseURL)
    }

    private func saveAndNavigate(to path: String) {
        saveServerURL()
        showingSettings = false
        navigate(to: path)
    }

    private func saveServerURL() {
        guard let normalizedURL = ServerSettings.normalizedServerURL(from: draftServerURL) else {
            validationMessage = "Enter a valid server URL."
            return
        }
        validationMessage = nil
        serverURL = normalizedURL.absoluteString
        draftServerURL = normalizedURL.absoluteString
        selectedURL = normalizedURL
    }
}

#Preview {
    ContentView()
}
