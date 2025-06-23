import SwiftUI

enum TypeDate {
    case start
    case end
}

struct MyHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: MyHistoryViewModel
    
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
    
    init(viewModel: MyHistoryViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        List {
            dateRangeSection
            transactionsSection
        }
        .applyListStyles()
        .toolbar { toolbarItems }
        .task {
            await viewModel.loadData(from: startDate, to: endDate)
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
            ForEach(Array(viewModel.sortedTransactions.enumerated()), id: \.element.id) { index, transaction in
                TransactionRow(transaction: transaction, viewModel: viewModel)
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
            changeDate(newValue: newValue, typeDate: type)
            Task { await viewModel.loadData(from: startDate, to: endDate) }
        }
    }
    
    private var sortingPicker: some View {
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
        }
    
    private var totalAmountRow: some View {
        ListRowView(
            categoryName: "Сумма",
            transactionAmount: NumberFormatter.currency.string(from: NSDecimalNumber(decimal: viewModel.totalAmount)) ?? "0 $",
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
                    }
                    .tint(Color.navigation)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AnalysisView()
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
            startDate = calendar.date(from: components) ?? newValue
            if startDate > endDate {
                endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: newValue) ?? newValue
            }
        case .end:
            components.hour = 23
            components.minute = 59
            endDate = calendar.date(from: components) ?? newValue
            if endDate < startDate {
                startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: newValue) ?? newValue
            }
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
    let transaction: Transaction
    let viewModel: MyHistoryViewModel
    
    var body: some View {
            let category = viewModel.category(for: transaction)
            let comment = transaction.comment ?? ""
            
            VStack(spacing: 0) {
                ListRowView(
                    emoji: category.map { String($0.emoji) } ?? "❓",
                    categoryName: category?.name ?? "Не известно",
                    transactionComment: comment.isEmpty ? nil : comment,
                    transactionAmount: NumberFormatter.currency.string(from: NSDecimalNumber(decimal: transaction.amount)) ?? "",
                    transactionDate: dateFormatted(date: transaction.transactionDate),
                    needChevron: true
                )
            }
            .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        }
    
    private func dateFormatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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

// MARK: - Color Extension (если нет в проекте)

extension Color {
    static let navigation = Color("navigation")
}

// MARK: - Preview

#Preview {
    MyHistoryView(viewModel: MyHistoryViewModel(
        transactionsService: TransactionsService(),
        categoriesService: CategoriesService(),
        selectedDirection: .outcome
    ))
}
