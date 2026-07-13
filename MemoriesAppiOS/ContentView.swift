import SwiftUI

struct ContentView: View {
    @AppStorage("serverURL") private var legacyServerURL = ServerSettings.defaultServerURL
    @AppStorage("savedServers") private var savedServersData = ""
    @AppStorage("selectedServerID") private var selectedServerID = ""

    @StateObject private var browserState = BrowserState()
    @State private var draftServerName = ""
    @State private var draftServerURL = ServerSettings.defaultServerURL
    @State private var draftUsername = ""
    @State private var draftPassword = ""
    @State private var editingServerID: UUID?
    @State private var selectedURL: URL?
    @State private var showingSettings = false
    @State private var validationMessage: String?

    private var savedServers: [SavedServer] {
        guard let data = savedServersData.data(using: .utf8),
              let servers = try? JSONDecoder().decode([SavedServer].self, from: data) else { return [] }
        return servers
    }

    private var selectedServer: SavedServer? {
        if let selectedID = UUID(uuidString: selectedServerID),
           let server = savedServers.first(where: { $0.id == selectedID }) {
            return server
        }
        return savedServers.first
    }

    private var baseURL: URL? {
        if let selectedServer {
            return ServerSettings.normalizedServerURL(from: selectedServer.url)
        }
        return ServerSettings.normalizedServerURL(from: legacyServerURL)
    }

    private var selectedCredential: ServerCredential? {
        guard let selectedServer, !selectedServer.username.isEmpty else { return nil }
        return ServerCredential(username: selectedServer.username, password: ServerCredentialStore.password(for: selectedServer.id))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let targetURL = selectedURL ?? baseURL {
                    VStack(spacing: 0) {
                        progressView
                        MemoriesWebView(targetURL: targetURL, state: browserState, credential: selectedCredential)
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
                            prepareDraftForSelectedServer()
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
                migrateLegacyServerIfNeeded()
                prepareDraftForSelectedServer()
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

            TextField("Name", text: $draftServerName)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)

            TextField("https://memories.example.com", text: $draftServerURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .textFieldStyle(.roundedBorder)

            TextField("Username", text: $draftUsername)
                .textInputAutocapitalization(.never)
                .textContentType(.username)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $draftPassword)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                saveDraftServer(selectAfterSaving: true)
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
                Section("Saved Servers") {
                    if savedServers.isEmpty {
                        Text("No saved servers")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(savedServers) { server in
                            Button {
                                selectServer(server)
                                prepareDraft(for: server)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(server.displayName)
                                            .foregroundStyle(.primary)
                                        Text(server.url)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                        if !server.username.isEmpty {
                                            Text(server.username)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if server.id.uuidString == selectedServerID {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteServers)
                    }
                }

                Section(editingServerID == nil ? "Add Server" : "Server Details") {
                    TextField("Name", text: $draftServerName)
                        .textInputAutocapitalization(.words)

                    TextField("Server URL", text: $draftServerURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    TextField("Username", text: $draftUsername)
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)

                    SecureField("Password", text: $draftPassword)
                        .textContentType(.password)

                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }

                    Button {
                        saveDraftServer(selectAfterSaving: true)
                    } label: {
                        Label(editingServerID == nil ? "Add Server" : "Save Server", systemImage: "server.rack")
                    }

                    if editingServerID != nil {
                        Button {
                            clearDraft()
                        } label: {
                            Label("Add New Server", systemImage: "plus")
                        }
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        validationMessage = nil
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
        let saved = saveDraftServer(selectAfterSaving: true)
        guard saved else { return }
        showingSettings = false
        navigate(to: path)
    }

    @discardableResult
    private func saveDraftServer(selectAfterSaving: Bool) -> Bool {
        guard let normalizedURL = ServerSettings.normalizedServerURL(from: draftServerURL) else {
            validationMessage = "Enter a valid HTTPS server URL."
            return false
        }

        var servers = savedServers
        let serverID = editingServerID ?? UUID()
        let name = draftServerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = draftUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let server = SavedServer(id: serverID, name: name, url: normalizedURL.absoluteString, username: username)

        if let index = servers.firstIndex(where: { $0.id == serverID }) {
            servers[index] = server
        } else {
            servers.append(server)
        }

        saveServers(servers)
        ServerCredentialStore.savePassword(draftPassword, for: serverID)
        validationMessage = nil
        editingServerID = serverID
        legacyServerURL = normalizedURL.absoluteString

        if selectAfterSaving {
            selectedServerID = serverID.uuidString
            selectedURL = normalizedURL
        }

        return true
    }

    private func selectServer(_ server: SavedServer) {
        selectedServerID = server.id.uuidString
        legacyServerURL = server.url
        selectedURL = ServerSettings.normalizedServerURL(from: server.url)
    }

    private func prepareDraftForSelectedServer() {
        if let selectedServer {
            prepareDraft(for: selectedServer)
        } else {
            clearDraft()
            draftServerURL = legacyServerURL
        }
    }

    private func prepareDraft(for server: SavedServer) {
        editingServerID = server.id
        draftServerName = server.name
        draftServerURL = server.url
        draftUsername = server.username
        draftPassword = ServerCredentialStore.password(for: server.id)
        validationMessage = nil
    }

    private func clearDraft() {
        editingServerID = nil
        draftServerName = ""
        draftServerURL = ""
        draftUsername = ""
        draftPassword = ""
        validationMessage = nil
    }

    private func deleteServers(at offsets: IndexSet) {
        var servers = savedServers
        let deletedServers = offsets.map { servers[$0] }
        servers.remove(atOffsets: offsets)
        deletedServers.forEach { ServerCredentialStore.deletePassword(for: $0.id) }
        saveServers(servers)

        if let selectedID = UUID(uuidString: selectedServerID), deletedServers.contains(where: { $0.id == selectedID }) {
            if let nextServer = servers.first {
                selectServer(nextServer)
            } else {
                selectedServerID = ""
                selectedURL = nil
                clearDraft()
            }
        }
    }

    private func migrateLegacyServerIfNeeded() {
        guard savedServers.isEmpty,
              let normalizedURL = ServerSettings.normalizedServerURL(from: legacyServerURL) else { return }

        let server = SavedServer(name: normalizedURL.host ?? "Memories", url: normalizedURL.absoluteString)
        saveServers([server])
        selectedServerID = server.id.uuidString
    }

    private func saveServers(_ servers: [SavedServer]) {
        guard let data = try? JSONEncoder().encode(servers),
              let value = String(data: data, encoding: .utf8) else { return }
        savedServersData = value
    }
}

#Preview {
    ContentView()
}
