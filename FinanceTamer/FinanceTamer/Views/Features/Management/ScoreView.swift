import SwiftUI

struct ScoreView: View {
    @StateObject private var viewModel = ScoreViewModel()
    @StateObject private var shakeDetector = ShakeDetector()
    @State private var isEditing = false
    @State private var showCurrencyPicker = false
    @State private var balanceText: String = ""
    @State private var isBalanceHidden = true
    @FocusState private var isBalanceFocused: Bool
    @EnvironmentObject var currencyService: CurrencyService
    
    private var errorBinding: Binding<String?> {
        Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        )
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    BalanceRow(
                        isEditing: isEditing,
                        balanceText: $balanceText,
                        isBalanceFocused: _isBalanceFocused,
                        isBalanceHidden: $isBalanceHidden,
                        currencySymbol: currencyService.currentCurrency.symbol,
                        viewModel: viewModel,
                        filterBalanceInput: filterBalanceInput
                    )
                    .contentShape(Rectangle())
                    .animation(.easeInOut(duration: 0.3), value: isBalanceHidden)
                    .listRowBackground(isEditing ? Color(.systemBackground) : Color.accentColor)
                    .onTapGesture {
                        if isEditing {
                            isBalanceFocused = true
                        }
                    }
                    
                    CurrencyRow(
                        isEditing: isEditing,
                        currency: currencyService.currentCurrency,
                        onTap: { showCurrencyPicker = true }
                    )
                    .listRowBackground(isEditing ? Color(.systemBackground) : Color.accentColor.opacity(0.2))
                    if !isEditing {
                        BalanceChartView(data: viewModel.balanceHistory)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listRowSpacing(16)
            .scrollDismissesKeyboard(.immediately)
            .refreshable {
                await viewModel.refreshAccount()
            }
            .onChange(of: isEditing) { editing in
                if (!editing) { isBalanceFocused = false }
            }
            .gesture(
                DragGesture().onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
            .navigationTitle("Мой счет")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Сохранить" : "Редактировать") {
                        if isEditing {
                            viewModel.saveChanges(balanceString: balanceText)
                        }
                        isEditing.toggle()
                        showCurrencyPicker = false
                    }
                    .tint(Color.navigation)
                }
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.1))
                            .zIndex(2)
                    }
                    if showCurrencyPicker {
                        Color.black.opacity(0.2)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showCurrencyPicker = false
                            }
                        
                        CurrencyPickerView(selectedCurrency: $currencyService.currentCurrency)
                    }
                }
            )
            .onAppear {
                viewModel.loadAccount()
            }
            .onReceive(shakeDetector.$shaken) { _ in
                viewModel.calculateBalanceHistory()
                guard !isEditing else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isBalanceHidden.toggle()
                }
            }
            .errorAlert(error: Binding(
                get: {
                    if let error = viewModel.errorMessage, !viewModel.isCancelledError(NSError(domain: error, code: 0)) {
                        return error
                    }
                    return nil
                },
                set: { viewModel.errorMessage = $0 }
            ))
        }
    }
    
    private func filterBalanceInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789,")
        let filtered = input.unicodeScalars.filter { allowedCharacters.contains($0) }
        var string = String(String.UnicodeScalarView(filtered))
        
        if let commaIndex = string.firstIndex(of: ",") {
            let beforeComma = String(string[..<commaIndex].prefix(15))
            let afterComma = String(string[string.index(after: commaIndex)...].prefix(2))
            string = beforeComma + "," + afterComma
        } else {
            string = String(string.prefix(15))
        }
        
        return string
    }
}

private struct BalanceRow: View {
    let isEditing: Bool
    @Binding var balanceText: String
    @FocusState var isBalanceFocused: Bool
    @Binding var isBalanceHidden: Bool
    let currencySymbol: String
    let viewModel: ScoreViewModel
    let filterBalanceInput: (String) -> String
    
    var body: some View {
        HStack {
            Text("💰 Баланс")
            Spacer()
            if isEditing {
                BalanceEditor(
                    balanceText: $balanceText,
                    isBalanceFocused: _isBalanceFocused,
                    currencySymbol: currencySymbol,
                    viewModel: viewModel,
                    filterBalanceInput: filterBalanceInput
                )
            } else {
                SpoilerText(
                    balance: viewModel.balanceString,
                    currencySymbol: currencySymbol,
                    isHidden: $isBalanceHidden
                )
            }
        }
    }
}

private struct BalanceEditor: View {
    @Binding var balanceText: String
    @FocusState var isBalanceFocused: Bool
    let currencySymbol: String
    let viewModel: ScoreViewModel
    let filterBalanceInput: (String) -> String
    
    var body: some View {
        HStack(spacing: 2) {
            TextField("", text: $balanceText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($isBalanceFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Готово") {
                            isBalanceFocused = false
                        }
                    }
                }
                .onAppear {
                    balanceText = viewModel.balanceString
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: currencySymbol, with: "")
                }
                .onChange(of: balanceText) { newValue in
                    balanceText = filterBalanceInput(newValue)
                }
                .foregroundColor(Color(white: 0.5))
                .contextMenu {
                    Button {
                        if let clipboardString = UIPasteboard.general.string {
                            balanceText = filterBalanceInput(clipboardString)
                        }
                    } label: {
                        Label("Вставить", systemImage: "doc.on.clipboard")
                    }
                }
            Text(currencySymbol)
        }
    }
}

private struct CurrencyRow: View {
    let isEditing: Bool
    let currency: Currency
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text("Валюта")
            Spacer()
            Text(currency.rawValue)
                .foregroundColor(isEditing ? Color(white: 0.5) : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                onTap()
            }
        }
    }
}

extension View {
    func errorAlert(error: Binding<String?>) -> some View {
        alert(
            "Ошибка",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error.wrappedValue ?? "Неизвестная ошибка")
        }
    }
}

#Preview {
    ScoreView()
}
