//
//  ContentView.swift
//  KeyInfo
//
//  Created by Paul Barnes on 12/03/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [KeyItem]
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .label
    @State private var showingSortOptions = false
    
    enum SortOption: String, CaseIterable {
        case label = "Label"
        case dateCreated = "Date Added"
        case category = "Category"
        
        var sortDescriptor: SortDescriptor<KeyItem> {
            switch self {
            case .label:
                return SortDescriptor(\KeyItem.label)
            case .dateCreated:
                return SortDescriptor(\KeyItem.dateCreated, order: .reverse)
            case .category:
                return SortDescriptor(\KeyItem.category)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("Key Info")
            .searchable(text: $searchText, prompt: "Search items...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Label(option.rawValue, systemImage: sortOptionIcon(option))
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddKeyItemView()
            }
        }
    }
    
    private var listView: some View {
        List {
            ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                Section(header: Text(category)) {
                    ForEach(groupedItems[category] ?? []) { item in
                        NavigationLink(destination: DetailView(item: item, onDelete: { deleteItem(item) })) {
                            KeyItemRow(item: item)
                        }
                    }
                    .onDelete { indexSet in
                        deleteItems(from: category, at: indexSet)
                    }
                }
            }
        }
        .animation(.default, value: sortOption)
        .animation(.default, value: searchText)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if searchText.isEmpty {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                
                Text("No Items Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap the + button to add your first key information item.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Button(action: { showingAddSheet = true }) {
                    Label("Add Item", systemImage: "plus.circle.fill")
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.top)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                
                Text("No Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("No items match your search for \"\(searchText)\"")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    
    private var filteredItems: [KeyItem] {
        let sortedItems = items.sorted(using: sortOption.sortDescriptor)
        
        if searchText.isEmpty {
            return sortedItems
        } else {
            return sortedItems.filter { item in
                item.label.localizedCaseInsensitiveContains(searchText) ||
                item.value.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var groupedItems: [String: [KeyItem]] {
        Dictionary(grouping: filteredItems) { $0.category }
    }
    
    private func sortOptionIcon(_ option: SortOption) -> String {
        switch option {
        case .label: return "textformat.abc"
        case .dateCreated: return "calendar"
        case .category: return "folder"
        }
    }
    
    private func deleteItems(from category: String, at offsets: IndexSet) {
        withAnimation {
            let itemsToDelete = offsets.map { groupedItems[category]![$0] }
            for item in itemsToDelete {
                deleteItem(item)
            }
        }
    }
    
    private func deleteItem(_ item: KeyItem) {
        modelContext.delete(item)
    }
}

struct KeyItemRow: View {
    let item: KeyItem
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(item.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(item.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.label)
                    .font(.headline)
                
                HStack {
                    Text(item.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                    
                    Spacer()
                    
                    Text(item.value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
