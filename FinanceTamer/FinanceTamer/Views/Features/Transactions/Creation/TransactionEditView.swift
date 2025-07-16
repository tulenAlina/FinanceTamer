import SwiftUI

struct TransactionEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var currencyService: CurrencyService
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    @StateObject private var viewModel: TransactionEditViewModel
    
    @State private var showCategoryPicker = false
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showDeleteConfirmation = false
    
    init(
        mode: TransactionEditViewModel.Mode,
        transactionsService: TransactionsService,
        categoriesService: CategoriesService,
        bankAccountsService: BankAccountsService,
        transactionsViewModel: TransactionsViewModel
    ) {
        _viewModel = StateObject(wrappedValue: TransactionEditViewModel(
            mode: mode,
            transactionsService: transactionsService,
            categoriesService: categoriesService,
            bankAccountsService: bankAccountsService,
            transactionsViewModel: transactionsViewModel        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(viewModel.navigationTitle)
                        .font(.system(size: 34, weight: .bold))
                        .padding(.bottom, 0)
                        .padding(.top, 0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                Section {
                    categoryRow
                    amountRow
                    dateRow
                    timeRow
                    commentRow
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                
                if case .edit = viewModel.mode {
                    Section {
                        deleteButton
                    }
                }
            }
            .padding(.top, -32)
            .alert("Заполните все поля", isPresented: $viewModel.showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.validationMessage)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
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
                    Button(viewModel.saveButtonTitle) {
                        Task {
                            await viewModel.save()
                        }
                    }
                    .foregroundColor(viewModel.isFormValid ? Color.navigation : .gray)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(
                    categories: viewModel.availableCategories,
                    selectedCategory: $viewModel.selectedCategory
                )
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerView
                    .presentationDetents([.medium, .large])
            }
            
            .sheet(isPresented: $showTimePicker) {
                timePickerView
                    .presentationDetents([.height(250)])
            }
            .confirmationDialog("Удалить операцию?", isPresented: $showDeleteConfirmation, actions: {
                Button("Удалить", role: .destructive) {
                    Task {
                        await viewModel.delete()
                        dismiss()
                    }
                }
                Button("Отмена", role: .cancel) {}
            })
            .onAppear {
                viewModel.loadData()
                viewModel.onSave = { dismiss() }
            }
            .onDisappear {
                if viewModel.saveSuccess {
                    Task {
                        await transactionsViewModel.loadTransactions()
                    }
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
            .alert("Ошибка", isPresented: Binding(
                get: { viewModel.error != nil && !(viewModel.error.map { viewModel.isCancelledError($0) } ?? false) },
                set: { newValue in if !newValue { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Неизвестная ошибка")
            }
        }
    }
    
    private var categoryRow: some View {
        HStack {
            Text("Статья")
            Spacer()
            if let category = viewModel.selectedCategory {
                Text(String(category.emoji) + " " + category.name)
                    .foregroundColor(.primary)
            } else {
                Text("Выберите статью")
                    .foregroundColor(viewModel.showValidationAlert && viewModel.selectedCategory == nil ? .red : .gray)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showCategoryPicker = true
        }
    }
    
    private var amountRow: some View {
        HStack {
            Text("Сумма")
            Spacer()
            TextField("0", text: $viewModel.amountText)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .foregroundColor(viewModel.showValidationAlert && viewModel.amountText.isEmpty ? .red : .primary)
                .onChange(of: viewModel.amountText) { _, newValue in
                    viewModel.amountText = formatAmountInput(newValue)
                }
            Text(currencyService.currentCurrency.symbol)
        }
    }
    
    private var dateRow: some View {
        HStack {
            Text("Дата")
            Spacer()
            Text(viewModel.dateString)
                .foregroundColor(.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(10)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showDatePicker = true
        }
    }
    
    private var timeRow: some View {
        HStack {
            Text("Время")
            Spacer()
            Text(viewModel.timeString)
                .foregroundColor(.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(10)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showTimePicker = true
        }
    }
    
    private var commentRow: some View {
        ZStack(alignment: .leading) {
            if viewModel.comment.isEmpty {
                Text("Комментарий")
                    .foregroundColor(.gray)
            }
            TextEditor(text: $viewModel.comment)
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Spacer()
                Text("Удалить операцию")
                Spacer()
            }
        }
    }
    
    private var datePickerView: some View {
        VStack {
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.date },
                    set: { newDate in
                        viewModel.date = newDate
                        if Calendar.current.isDate(newDate, inSameDayAs: Date()) && viewModel.time > Date() {
                            viewModel.time = Date()
                        }
                    }
                ),
                in: ...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .frame(maxHeight: 400)
            .padding()
        }
        .padding()
    }
    private var timePickerView: some View {
        VStack {
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.time },
                    set: { newTime in
                        if Calendar.current.isDate(viewModel.date, inSameDayAs: Date()) && newTime > Date() {
                            viewModel.time = Date()
                        } else {
                            viewModel.time = newTime
                        }
                    }
                ),
                in: ...(Calendar.current.isDate(viewModel.date, inSameDayAs: Date()) ? Date() : Date.distantFuture),
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            
            Button("Готово") {
                showTimePicker = false
            }
            .padding()
        }
        .padding()
        .onChange(of: viewModel.date) { _, newDate in
            if Calendar.current.isDate(newDate, inSameDayAs: Date()) && viewModel.time > Date() {
                viewModel.time = Date()
            }
        }
    }
    
    private func formatAmountInput(_ input: String) -> String {
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let allowedCharacters = CharacterSet(charactersIn: "0123456789" + decimalSeparator)
        let filtered = input.unicodeScalars.filter { allowedCharacters.contains($0) }
        var string = String(String.UnicodeScalarView(filtered))
        
        if let separatorIndex = string.firstIndex(of: Character(decimalSeparator)) {
            let beforeSeparator = String(string[..<separatorIndex])
            let afterSeparator = String(string[string.index(after: separatorIndex)...].prefix(2))
            string = beforeSeparator + decimalSeparator + afterSeparator
        }
        
        return string
    }
}

