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
    @State private var showingSettingsSheet = false
    @State private var activeItem: KeyItem?
    @State private var showingDetailSheet = false
    @State private var editModeActive = false
    
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
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Image(systemName: "gear")
                        }
                        
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
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button {
                            showingAboutSheet = true
                        } label: {
                            Label("About", systemImage: "info.circle")
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
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
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
            .sheet(isPresented: $showingDetailSheet) {
                if let item = activeItem {
                    NavigationStack {
                        DetailView(
                            item: item,
                            onDelete: { 
                                deleteItem(item)
                                showingDetailSheet = false
                            },
                            startEditing: editModeActive,
                            isReadOnly: !editModeActive
                        )
                    }
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
                        ZStack {
                            NavigationLink(destination: DetailView(
                                item: item, 
                                onDelete: { deleteItem(item) },
                                isReadOnly: true
                            )) {
                                EmptyView()
                            }
                            .opacity(0)
                            .buttonStyle(.plain)
                            
                            KeyItemRow(item: item, onLikeToggle: {
                                toggleLike(item)
                            }, onViewDetails: {
                                // We use a programmatic approach to trigger the navigation
                                navigateToItem(item)
                            })
                            .contentShape(Rectangle())
                            .onTapGesture {
                                copyToClipboard(item.value)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteItem(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                navigateToItem(item, startEditing: true)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            deleteItem(favorites[index])
                        }
                    }
                }
            }
            
            // Regular category groups
            ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                Section(header: Text(category)) {
                    ForEach(groupedItems[category] ?? []) { item in
                        ZStack {
                            NavigationLink(destination: DetailView(
                                item: item, 
                                onDelete: { deleteItem(item) },
                                isReadOnly: true
                            )) {
                                EmptyView()
                            }
                            .opacity(0)
                            .buttonStyle(.plain)
                            
                            KeyItemRow(item: item, onLikeToggle: {
                                toggleLike(item)
                            }, onViewDetails: {
                                // We use a programmatic approach to trigger the navigation
                                navigateToItem(item)
                            })
                            .contentShape(Rectangle())
                            .onTapGesture {
                                copyToClipboard(item.value)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteItem(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                navigateToItem(item, startEditing: true)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
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
        .listStyle(.insetGrouped)
    }
    
    private var flatListView: some View {
        List {
            ForEach(filteredItems) { item in
                ZStack {
                    NavigationLink(destination: DetailView(
                        item: item, 
                        onDelete: { deleteItem(item) },
                        isReadOnly: true
                    )) {
                        EmptyView()
                    }
                    .opacity(0)
                    .buttonStyle(.plain)
                    
                    KeyItemRow(item: item, onLikeToggle: {
                        toggleLike(item)
                    }, onViewDetails: {
                        // We use a programmatic approach to trigger the navigation
                        navigateToItem(item)
                    })
                    .contentShape(Rectangle())
                    .onTapGesture {
                        copyToClipboard(item.value)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        navigateToItem(item, startEditing: true)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .animation(.default, value: sortOption)
        .animation(.default, value: searchText)
        .listStyle(.insetGrouped)
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
    
    // Add these helper methods for navigation
    private func navigateToItem(_ item: KeyItem, startEditing: Bool = false) {
        activeItem = item
        editModeActive = startEditing
        showingDetailSheet = true
    }
    
    private func navigateToDetails(_ item: KeyItem) {
        // We rely on the NavigationLink to handle the navigation
        // The onViewDetails callback is just to capture the tap
    }
    
    private func navigateToEdit(_ item: KeyItem) {
        // Implementation will use the NavigationLink but with edit mode enabled
    }
}

#Preview {
    ContentView()
} 