import SwiftUI

enum TypeDate {
    case start
    case end
}

struct MyHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    
    @State private var startDate: Date = {
        let calendar = Calendar.current
        let today = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) ?? today
        let components = calendar.dateComponents([.year, .month, .day], from: monthAgo)
        return calendar.date(from: components) ?? today
    }()
    
    @State private var endDate: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        components.hour = 23
        components.minute = 59
        return calendar.date(from: components) ?? Date()
    }()
    
    @State private var sortType: SortType = .dateAscending
    
    var filteredTransactions: [TransactionResponse] {
        let isoFormatter = ISO8601DateFormatter()
        let validStartDate = startDate
        let validEndDate = endDate >= startDate ? endDate : startDate
        let dateRange = validStartDate...validEndDate
        return transactionsViewModel.allTransactions.filter { transaction in
            guard let category = transactionsViewModel.category(for: transaction) else { return false }
            guard let date = isoFormatter.date(from: transaction.transactionDate) else { return false }
            return dateRange.contains(date) && category.direction == transactionsViewModel.selectedDirection
        }
    }
    
    var sortedTransactions: [TransactionResponse] {
        let isoFormatter = ISO8601DateFormatter()
        switch sortType {
        case .dateAscending:
            return filteredTransactions.sorted {
                let d0 = isoFormatter.date(from: $0.transactionDate) ?? Date.distantPast
                let d1 = isoFormatter.date(from: $1.transactionDate) ?? Date.distantPast
                return d0 < d1
            }
        case .dateDescending:
            return filteredTransactions.sorted {
                let d0 = isoFormatter.date(from: $0.transactionDate) ?? Date.distantPast
                let d1 = isoFormatter.date(from: $1.transactionDate) ?? Date.distantPast
                return d0 > d1
            }
        case .amountAscending:
            return filteredTransactions.sorted { (Decimal(string: $0.amount) ?? 0) < (Decimal(string: $1.amount) ?? 0) }
        case .amountDescending:
            return filteredTransactions.sorted { (Decimal(string: $0.amount) ?? 0) > (Decimal(string: $1.amount) ?? 0) }
        }
    }
    
    var totalAmount: Decimal {
        sortedTransactions.reduce(0) { $0 + (Decimal(string: $1.amount) ?? 0) }
    }
    
    var body: some View {
        List {
            dateRangeSection
            transactionsSection
        }
        .applyListStyles()
        .toolbar { toolbarItems }
        .task {
            await transactionsViewModel.loadTransactions()
        }
        .overlay(
            Group {
                if transactionsViewModel.isLoading {
                    Color.black.opacity(0.1).ignoresSafeArea()
                    ProgressView()
                }
            }
        )
        .alert("Ошибка", isPresented: Binding(
            get: { transactionsViewModel.error != nil },
            set: { newValue in if !newValue { transactionsViewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) { transactionsViewModel.error = nil }
        } message: {
            Text(transactionsViewModel.error?.localizedDescription ?? "Неизвестная ошибка")
        }
    }
    
    // MARK: - Subviews
    
    private var dateRangeSection: some View {
        Section {
            datePickerRow(title: "Начало", date: $startDate, type: .start)
            datePickerRow(title: "Конец", date: $endDate, type: .end)
            sortingPicker
            totalAmountRow
        } header: {
            historyHeader
        }
    }
    
    private var transactionsSection: some View {
        Section {
            ForEach(Array(sortedTransactions.enumerated()), id: \.element.id) { index, transaction in
                NavigationLink {
                    TransactionEditView(
                        mode: .edit(transaction),
                        transactionsService: TransactionsService(),
                        categoriesService: CategoriesService(),
                        bankAccountsService: BankAccountsService(),
                        transactionsViewModel: transactionsViewModel
                    )
                    .environmentObject(CurrencyService())
                    .environmentObject(transactionsViewModel)
                    .onDisappear {
                        Task {
                            await transactionsViewModel.loadTransactions()
                        }
                    }
                } label: {
                    TransactionRow(transaction: transaction)
                        .environmentObject(transactionsViewModel)
                }
            }
        } header: {
            operationsHeader
        }
    }
    
    private func datePickerRow(title: String, date: Binding<Date>, type: TypeDate) -> some View {
        HStack {
            Text(title)
            Spacer()
            CustomPickerView(date: date)
        }
        .onChange(of: date.wrappedValue) { _, newValue in
            // Добавляем небольшую задержку для корректной обработки изменений
            DispatchQueue.main.async {
                changeDate(newValue: newValue, typeDate: type)
            }
        }
    }
    
    private var sortingPicker: some View {
        HStack {
            Text("Сортировка")
            Spacer()
            Picker("", selection: $sortType) {
                ForEach(SortType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    private var totalAmountRow: some View {
        ListRowView(
            categoryName: "Сумма",
            transactionAmount: NumberFormatter.currency(symbol: "₽").string(from: NSDecimalNumber(decimal: totalAmount)) ?? "0 ₽",
            needChevron: false
        )
    }
    
    private var historyHeader: some View {
        Text("Моя история")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(.black)
            .padding(.bottom, 16)
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
    }
    
    private var operationsHeader: some View {
        Text("ОПЕРАЦИИ")
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.secondary)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Назад")
                    }.foregroundStyle(Color.navigation)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AnalysisView(selectedDirection: transactionsViewModel.selectedDirection)
                } label: {
                    Image("document")
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(Color.navigation)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func changeDate(newValue: Date, typeDate: TypeDate) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: newValue)
        
        switch typeDate {
        case .start:
            components.hour = 00
            components.minute = 00
            components.second = 00
            let newStartDate = calendar.date(from: components) ?? newValue
            
            // Если новая начальная дата больше конечной, устанавливаем конечную дату равной начальной
            if newStartDate > endDate {
                var endComponents = calendar.dateComponents([.year, .month, .day], from: newStartDate)
                endComponents.hour = 23
                endComponents.minute = 59
                endComponents.second = 59
                endDate = calendar.date(from: endComponents) ?? newStartDate
            }
            
            startDate = newStartDate
            
        case .end:
            components.hour = 23
            components.minute = 59
            components.second = 59
            let newEndDate = calendar.date(from: components) ?? newValue
            
            // Если новая конечная дата меньше начальной, устанавливаем начальную дату равной конечной
            if newEndDate < startDate {
                var startComponents = calendar.dateComponents([.year, .month, .day], from: newEndDate)
                startComponents.hour = 00
                startComponents.minute = 00
                startComponents.second = 00
                startDate = calendar.date(from: startComponents) ?? newEndDate
            }
            
            endDate = newEndDate
        }
    }
    
    private func dateFormator(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
}

// MARK: - Transaction Row View

struct TransactionRow: View {
    let transaction: TransactionResponse
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    
    var body: some View {
        let category = getCategory(for: transaction)
        let comment = transaction.comment ?? ""
        
        VStack(spacing: 0) {
            ListRowView(
                emoji: category.map { String($0.emoji) } ?? "❓",
                categoryName: category?.name ?? "Не известно",
                transactionComment: comment.isEmpty ? nil : comment,
                transactionAmount: NumberFormatter.currency(symbol: "₽").string(from: NSDecimalNumber(decimal: Decimal(string: transaction.amount) ?? 0)) ?? "",
                transactionDate: dateFormatted(date: transaction.transactionDate),
                needChevron: false
            )
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
    }
    
    private func dateFormatted(date: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: date) else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
    
    private func getCategory(for transaction: TransactionResponse) -> Category? {
        return transactionsViewModel.category(for: transaction)
    }
}

// MARK: - View Extensions

extension View {
    func applyListStyles() -> some View {
        self
            .listSectionSpacing(0)
            .scrollIndicators(.hidden)
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Color Extension

extension Color {
    static let navigation = Color("navigationColor")
}

// MARK: - Preview

#Preview {
    let currencyService = CurrencyService()
    MyHistoryView()
        .environmentObject(TransactionsViewModel(
            transactionsService: TransactionsService(),
            categoriesService: CategoriesService(),
            selectedDirection: .outcome
        ))
        .environmentObject(currencyService)
}
