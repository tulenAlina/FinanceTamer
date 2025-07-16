import SwiftUI

struct TransactionsListView: View {
    @EnvironmentObject var viewModel: TransactionsViewModel
    private let title: String
    
    init(title: String) {
        self.title = title
    }
    
    var body: some View {
        let transactions = viewModel.displayedTransactions
        return NavigationStack {
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
                            transactionAmount: NumberFormatter.currency(symbol: "₽").string(from: NSDecimalNumber(decimal: viewModel.totalAmount)) ?? "0 ₽",
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
                        ForEach(transactions) { transaction in
                            TransactionRowNavigationView(transaction: transaction, viewModel: viewModel)
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
                .alert("Ошибка", isPresented: Binding(
                    get: { viewModel.error != nil && !(viewModel.error.map { viewModel.isCancelledError($0) } ?? false) },
                    set: { newValue in if !newValue { viewModel.error = nil } }
                )) {
                    Button("OK", role: .cancel) { viewModel.error = nil }
                } message: {
                    Text(viewModel.error?.localizedDescription ?? "Неизвестная ошибка")
                }
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        Color.black.opacity(0.1).ignoresSafeArea()
                        ProgressView()
                    }
                }
            )
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

// Компонент для строки транзакции
struct TransactionRowNavigationView: View {
    let transaction: TransactionResponse
    @ObservedObject var viewModel: TransactionsViewModel
    var body: some View {
        let category = viewModel.category(for: transaction)
        return NavigationLink {
            TransactionEditView(
                mode: .edit(transaction),
                transactionsService: TransactionsService(),
                categoriesService: CategoriesService(),
                bankAccountsService: BankAccountsService(),
                transactionsViewModel: viewModel
            )
            .environmentObject(CurrencyService())
            .environmentObject(viewModel)
            // .onDisappear удалён, чтобы не было лишних вызовов загрузки
        } label: {
            VStack(spacing: 0) {
                ListRowView(
                    emoji: category.map { String($0.emoji) } ?? "❓",
                    categoryName: category?.name ?? "Неизвестно",
                    transactionComment: transaction.comment?.isEmpty == false ? transaction.comment : nil,
                    transactionAmount: NumberFormatter.currency(symbol: "₽").string(from: NSDecimalNumber(decimal: Decimal(string: transaction.amount) ?? 0)) ?? "",
                    needChevron: false
                )
            }
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
            viewDimensions[.listRowSeparatorLeading] + 46
        }
    }
}
