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
    @Query(sort: \KeyItem.dateCreated, order: .reverse) private var items: [KeyItem]
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .label
    @State private var showingSortOptions = false
    @State private var lastCopiedValue: String?
    @State private var showCopiedToast = false
    @State private var showingAboutSheet = false
    @AppStorage("isGroupedByCategory") private var isGroupedByCategory = true
    
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
                    if isGroupedByCategory {
                        groupedListView
                    } else {
                        flatListView
                    }
                }
                
                // Toast overlay
                if showCopiedToast, let value = lastCopiedValue {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                            Text("Copied: \(value)")
                                .lineLimit(1)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
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
                    HStack {
                        Menu {
                            Picker("Sort By", selection: $sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Label(option.rawValue, systemImage: sortOptionIcon(option))
                                }
                            }
                            
                            Divider()
                            
                            Toggle(isOn: $isGroupedByCategory) {
                                Label("Group by Category", systemImage: isGroupedByCategory ? "folder.fill" : "list.bullet")
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                        
                        Button {
                            showingAboutSheet = true
                        } label: {
                            Label("About", systemImage: "info.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddKeyItemView()
            }
            .sheet(isPresented: $showingAboutSheet) {
                NavigationStack {
                    AboutView()
                }
            }
        }
    }
    
    private var groupedListView: some View {
        List {
            // Add a "Favorites" section at the top containing all liked items
            let favorites = filteredItems.filter { $0.isLikedSafe }
            if !favorites.isEmpty {
                Section(header: Text("⭐ Favorites")) {
                    ForEach(favorites) { item in
                        KeyItemRowWithActions(
                            item: item,
                            onCopy: { copyToClipboard(item.value) },
                            onDelete: { deleteItem(item) },
                            onLikeToggle: { toggleLike(item) }
                        )
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            deleteItem(favorites[index])
                        }
                    }
                }
            }
            
            // Regular category groups (keep the existing logic)
            ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                Section(header: Text(category)) {
                    ForEach(groupedItems[category] ?? []) { item in
                        KeyItemRowWithActions(
                            item: item,
                            onCopy: { copyToClipboard(item.value) },
                            onDelete: { deleteItem(item) },
                            onLikeToggle: { toggleLike(item) }
                        )
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
    
    private var flatListView: some View {
        List {
            ForEach(filteredItems) { item in
                KeyItemRowWithActions(
                    item: item,
                    onCopy: { copyToClipboard(item.value) },
                    onDelete: { deleteItem(item) },
                    onLikeToggle: { toggleLike(item) }
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    deleteItem(filteredItems[index])
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
        // First sort by liked status, then by the selected sort option
        let sortedItems = items.sorted {
            if $0.isLikedSafe != $1.isLikedSafe {
                return $0.isLikedSafe && !$1.isLikedSafe
            }
            
            // If like status is the same, use the selected sort option
            switch sortOption {
            case .label:
                return $0.label < $1.label
            case .dateCreated:
                return $0.dateCreated > $1.dateCreated
            case .category:
                return $0.category < $1.category
            }
        }
        
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
        // Group items by category
        let grouped = Dictionary(grouping: filteredItems) { $0.category }
        
        // Sort items within each category to keep liked items at the top
        var sortedGrouped = [String: [KeyItem]]()
        for (category, items) in grouped {
            sortedGrouped[category] = items.sorted {
                if $0.isLikedSafe != $1.isLikedSafe {
                    return $0.isLikedSafe && !$1.isLikedSafe
                }
                // Secondary sort based on the selected sort option
                switch sortOption {
                case .label:
                    return $0.label < $1.label
                case .dateCreated:
                    return $0.dateCreated > $1.dateCreated
                case .category:
                    return $0.label < $1.label // Fall back to label when already sorted by category
                }
            }
        }
        
        return sortedGrouped
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
    
    private func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
        lastCopiedValue = value
        
        withAnimation {
            showCopiedToast = true
        }
        
        // Hide the toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
    
    private func toggleLike(_ item: KeyItem) {
        // Toggle the isLiked value, handling the optional properly
        item.isLiked = !(item.isLiked ?? false)
        
        // Explicitly save changes to ensure persistence
        do {
            try modelContext.save()
        } catch {
            print("Error saving like status: \(error.localizedDescription)")
        }
    }
}

struct KeyItemRow: View {
    let item: KeyItem
    @Environment(\.colorScheme) private var colorScheme
    var onLikeToggle: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(item.color)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if item.isLikedSafe {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                    
                    Text(item.label)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(item.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                }
                
                Text(item.value)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.color.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    )
            }
            
            Button {
                onLikeToggle?()
            } label: {
                Image(systemName: item.isLikedSafe ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(item.isLikedSafe ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct KeyItemRowWithActions: View {
    let item: KeyItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onLikeToggle: () -> Void
    
    var body: some View {
        Button {
            onCopy()
        } label: {
            KeyItemRow(item: item, onLikeToggle: onLikeToggle)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button {
                onCopy()
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
            
            Button {
                onLikeToggle()
            } label: {
                Label((item.isLikedSafe) ? "Unlike" : "Like", systemImage: (item.isLikedSafe) ? "star.slash" : "star")
            }
            
            NavigationLink {
                DetailView(item: item, onDelete: onDelete, startEditing: true)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            NavigationLink {
                DetailView(item: item, onDelete: onDelete, startEditing: true)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading) {
            Button {
                onLikeToggle()
            } label: {
                Label((item.isLikedSafe) ? "Unlike" : "Like", systemImage: (item.isLikedSafe) ? "star.slash" : "star")
            }
            .tint(.yellow)
        }
    }
}

#Preview("KeyItemRowWithActions") {
    NavigationStack {
        List {
            KeyItemRowWithActions(
                item: KeyItem(label: "Test Item", value: "Test Value", iconName: "key.fill"),
                onCopy: {},
                onDelete: {},
                onLikeToggle: {}
            )
        }
    }
}

#Preview {
    ContentView()
}
