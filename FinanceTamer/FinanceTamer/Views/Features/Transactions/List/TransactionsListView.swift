import SwiftUI

struct TransactionsListView: View {
    @EnvironmentObject var viewModel: TransactionsViewModel
    private let title: String
    
    init(title: String) {
        self.title = title
    }
    
    var body: some View {
        NavigationStack {
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
                            transactionAmount: NumberFormatter.currency.string(from: NSDecimalNumber(decimal: viewModel.totalAmount)) ?? "0 ₽",
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
                        ForEach(viewModel.displayedTransactions) { transaction in
                            let category = viewModel.category(for: transaction)
                            
                            NavigationLink {
                                TransactionEditView(
                                    mode: .edit(transaction),
                                    transactionsService: TransactionsService(),
                                    categoriesService: CategoriesService(),
                                    bankAccountsService: BankAccountsService.shared,
                                    transactionsViewModel: viewModel
                                )
                                .environmentObject(CurrencyService.shared)
                                .environmentObject(viewModel)
                                .onDisappear {
                                    Task {
                                        await viewModel.loadTransactions()
                                    }
                                }
                            } label: {
                                VStack(spacing: 0) {
                                    ListRowView(
                                        emoji: category.map { String($0.emoji) } ?? "❓",
                                        categoryName: category?.name ?? "Не известно",
                                        transactionComment: transaction.comment?.isEmpty == false ? transaction.comment : nil,
                                        transactionAmount: NumberFormatter.currency.string(from: NSDecimalNumber(decimal: transaction.amount)) ?? "",
                                        needChevron: false
                                    )
                                }
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
                .onChange(of: viewModel.displayedTransactions) { _, _ in
                    // Автоматическое обновление при изменении транзакций
                }
            }
        }
    }
}

#Preview {
    TransactionsListView(title: "Расходы сегодня")
        .environmentObject(TransactionsViewModel(
            transactionsService: TransactionsService(),
            categoriesService: CategoriesService(),
            selectedDirection: .outcome
        ))
}
