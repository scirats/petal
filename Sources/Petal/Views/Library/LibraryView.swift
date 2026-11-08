import Combine
import PetalCore
import SwiftUI

struct LibraryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @State private var showingNewMachine = false

    var body: some View {
        @Bindable var model = model

        PetalRoot {
            HStack(spacing: 0) {
                sidebar(selection: $model.selection)
                detail
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showingNewMachine = true
                } label: {
                    Label("New Machine", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .help("New Machine")
            }
        }
        .focusedSceneValue(\.newMachineAction) {
            showingNewMachine = true
        }
        .sheet(isPresented: $showingNewMachine) {
            NewMachineSheet()
        }
        .onChange(of: model.launchRequest) {
            handleLaunchRequest()
        }
        .alert("Error", isPresented: showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.alert ?? "")
        }
        .onAppear(perform: autostartIfRequested)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.reload()
        }
    }

    private func sidebar(selection: Binding<URL?>) -> some View {
        VStack(spacing: 0) {
            if !model.installs.jobs.isEmpty {
                PetalSection("In Progress") {
                    ForEach(model.installs.jobs) { job in
                        InstallRow(job: job)
                    }
                }
                .padding(PetalSpacing.medium)
            }

            PetalSidebarList(items: model.machines, selection: selection) { entry in
                machineRow(for: entry)
            }
        }
        .frame(width: PetalMetrics.sidebarWidth)
        .petalSidebarBackground()
    }

    private func machineRow(for entry: MachineEntry) -> some View {
        let session = model.session(for: entry)
        return MachineRow(entry: entry, session: session)
            .contextMenu {
                MachineActionsMenu(entry: entry, session: session)
            }
    }

    @ViewBuilder
    private var detail: some View {
        if model.machines.isEmpty && model.installs.jobs.isEmpty {
            PetalEmptyState(
                systemImage: "shippingbox",
                title: "No machines",
                message: "Download a Linux distribution to get started."
            ) {
                PetalActionButton(title: "New Machine", isTinted: true) {
                    showingNewMachine = true
                }
            }
        } else if let url = model.selection, let entry = model.entry(for: url) {
            MachineDetailView(entry: entry, session: model.session(for: entry))
                .id(entry.id)
        } else {
            PetalEmptyState(
                systemImage: "macwindow",
                title: "Select a machine",
                message: "Pick a machine from the sidebar to see its details."
            )
        }
    }

    private var showingAlert: Binding<Bool> {
        Binding(
            get: { model.alert != nil },
            set: { if !$0 { model.alert = nil } }
        )
    }

    private func handleLaunchRequest() {
        guard let bundle = model.launchRequest else { return }
        model.launchRequest = nil
        openWindow(id: "machine", value: bundle.url)
        Task { await model.sessions.session(for: bundle).start() }
    }

    private func autostartIfRequested() {
        guard let name = UserDefaults.standard.string(forKey: "PetalAutostart"),
              let entry = model.machines.first(where: { $0.config.name == name })
        else { return }

        UserDefaults.standard.removeObject(forKey: "PetalAutostart")
        model.selection = entry.id
        openWindow(id: "machine", value: entry.id)
        Task { await model.session(for: entry).start() }
    }
}
