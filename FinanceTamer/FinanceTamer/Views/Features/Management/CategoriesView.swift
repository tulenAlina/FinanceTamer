import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewModel = CategoriesViewModel()
    @State private var searchText = ""
    @State private var selectedDirection: Direction = .outcome
    
    var body: some View {
        NavigationStack {
            List {
                
                // Переключатель
                Section {
                    Picker("Тип категорий", selection: $selectedDirection) {
                        Text("Расходы").tag(Direction.outcome)
                        Text("Доходы").tag(Direction.income)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                
                // Секция с категориями
                Section("Cтатьи") {
                    ForEach(filteredCategories) { category in
                        CategoryRow(category: category)
                    }
                }
            }
            .listSectionSpacing(0)
            //.scrollIndicators(.hidden)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Мои статьи")
            .background(Color(.systemGroupedBackground))
            .task {
                await viewModel.loadCategories(for: selectedDirection)
            }
            .onChange(of: selectedDirection) {
                Task {
                    await viewModel.loadCategories(for: selectedDirection)
                }
            }
        }
    }
    
    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return viewModel.categories
        } else {
            return FuzzySearch.search(text: searchText, in: viewModel.categories)
        }
    }
}

#Preview {
    CategoriesView()
}
