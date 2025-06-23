import SwiftUI

struct TransactionsListView: View {
    @StateObject private var viewModel: TransactionsViewModel
    private let title: String
    
    init(
        transactionsService: TransactionsService,
        categoriesService: CategoriesService,
        direction: Direction,
        title: String
    ) {
        self._viewModel = StateObject(
            wrappedValue: TransactionsViewModel(
                transactionsService: transactionsService,
                categoriesService: categoriesService,
                selectedDirection: direction
            )
        )
        self.title = title
    }
    
    var body: some View {
            ZStack {
                List {
                    Section {
                        HStack {
                            Text("Сортировка")
                            Spacer()
                            Picker("", selection: $viewModel.sortType) {
                                ForEach(SortType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        ListRowView(
                            categoryName: "Всего",
                            transactionAmount: viewModel.totalAmountToday,
                            needChevron: false
                        )
                    } header: {
                    Text(title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.bottom, 16)
                        .textCase(nil)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                
                Section {
                    ForEach(viewModel.displayedTransactions.indices, id: \.self) { index in
                        let transaction = viewModel.displayedTransactions[index]
                        let category = viewModel.category(for: transaction)
                        VStack(spacing: 0) {
                            ListRowView(
                                emoji: category.map { String($0.emoji) } ?? "❓",
                                categoryName: category?.name ?? "Не известно",
                                transactionComment: transaction.comment?.count != 0 ? transaction.comment : nil,
                                transactionAmount: NumberFormatter.currency.string(from: NSDecimalNumber(decimal: transaction.amount)) ?? "",
                                needChevron: true
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                            return viewDimensions[.listRowSeparatorLeading] + 46
                        }
                    }
                    
                } header: {
                    Text("ОПЕРАЦИИ")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
            }
            .listSectionSpacing(0)
            .scrollIndicators(.hidden)
            .task {
                await viewModel.loadTransactions()
            }
            .refreshable {
                await viewModel.loadTransactions()
            }
        }
    }
}

#Preview {
    TransactionsListView(
        transactionsService: TransactionsService(),
        categoriesService: CategoriesService(),
        direction: .outcome,
        title: "Расходы сегодня"
    )
}
