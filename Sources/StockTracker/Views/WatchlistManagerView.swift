import SwiftUI

struct WatchlistManagerView: View {
    @ObservedObject var viewModel: StockListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newWatchlistName = ""
    @State private var editingWatchlistId: UUID?
    @State private var editingName = ""

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            watchlistList
            Divider()
            createWatchlistSection
        }
        .frame(width: 400, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Manage Watchlists")
                    .font(.system(size: 17, weight: .bold))
                Text("Create, rename, or delete watchlists")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var watchlistList: some View {
        List {
            ForEach(viewModel.store.watchlists) { watchlist in
                HStack {
                    if editingWatchlistId == watchlist.id {
                        TextField("Watchlist name", text: $editingName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if !editingName.isEmpty {
                                    viewModel.store.renameWatchlist(id: watchlist.id, name: editingName)
                                }
                                editingWatchlistId = nil
                            }
                    } else {
                        Button {
                            viewModel.store.selectWatchlist(id: watchlist.id)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: viewModel.store.currentWatchlistId == watchlist.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.store.currentWatchlistId == watchlist.id ? .accentColor : .secondary)
                                Text(watchlist.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(watchlist.symbols.count) stocks")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    if editingWatchlistId != watchlist.id {
                        Button {
                            editingName = watchlist.name
                            editingWatchlistId = watchlist.id
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.borderless)

                        if viewModel.store.watchlists.count > 1 {
                            Button(role: .destructive) {
                                viewModel.store.deleteWatchlist(id: watchlist.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.inset)
    }

    private var createWatchlistSection: some View {
        HStack(spacing: 12) {
            TextField("New watchlist name", text: $newWatchlistName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    createWatchlist()
                }

            Button {
                createWatchlist()
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .disabled(newWatchlistName.trimmingCharacters(in: .whitespaces).isEmpty)
            .buttonStyle(.borderless)
        }
        .padding(16)
    }

    private func createWatchlist() {
        let name = newWatchlistName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.store.createWatchlist(name: name)
        newWatchlistName = ""
    }
}
