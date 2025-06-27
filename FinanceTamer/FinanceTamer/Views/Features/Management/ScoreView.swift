import SwiftUI

struct ScoreView: View {
    @StateObject private var viewModel = ScoreViewModel()
    @StateObject private var shakeDetector = ShakeDetector()
    @State private var isEditing = false
    @State private var showCurrencyPicker = false
    @State private var balanceText: String = ""
    @State private var isBalanceHidden = true
    @FocusState private var isBalanceFocused: Bool
    
    private var currencySymbol: String {
        switch viewModel.currency {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Строка баланса
                    HStack {
                        Text("💰 Баланс")
                        Spacer()
                        
                        if isEditing {
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
                                    .onChange(of: isEditing) { newValue in
                                        if newValue {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                isBalanceFocused = true
                                            }
                                        }
                                    }
                                    .onChange(of: balanceText) { newValue in
                                        balanceText = filterBalanceInput(newValue)
                                    }
                                    .foregroundColor(isEditing ? Color(white: 0.5) : .primary)
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
                        } else {
                            SpoilerText(
                                balance: viewModel.balanceString,
                                currencySymbol: currencySymbol,
                                isHidden: $isBalanceHidden
                            )
                        }
                    }
                    .contentShape(Rectangle())
                    .animation(.easeInOut(duration: 0.3), value: isBalanceHidden)
                    .listRowBackground(isEditing ? Color(.systemBackground) : Color.accentColor)
                    .onTapGesture {
                        if !isEditing {
                            isEditing = true
                        }
                    }
                    
                    // Строка валюты
                    HStack {
                        Text("Валюта")
                        Spacer()
                        Text(viewModel.currency.rawValue)
                            .foregroundColor(isEditing ? Color(white: 0.5) : .primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isEditing {
                            showCurrencyPicker = true
                        }
                    }
                    .listRowBackground(isEditing ? Color(.systemBackground) : Color.accentColor.opacity(0.2))
                }
            }
            .listStyle(.insetGrouped)
            .listRowSpacing(16)
            .refreshable {
                await viewModel.refreshAccount()
            }
            .onChange(of: isEditing) { editing in
                if !editing {
                    isBalanceFocused = false
                }
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
                    }
                    .tint(Color.navigation)
                }
            }
            .overlay(
                Group {
                    if showCurrencyPicker {
                        Color.black.opacity(0.2)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showCurrencyPicker = false
                            }
                        
                        CurrencyPickerView(selectedCurrency: $viewModel.currency)
                            .environmentObject(CurrencyService.shared)
                    }
                }
            )
            .onAppear {
                viewModel.loadAccount()
            }
            .onReceive(shakeDetector.$shaken) { _ in
                guard !isEditing else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isBalanceHidden.toggle()
                }
            }
        }
    }
    
    private func filterBalanceInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789,")
        let filtered = input.unicodeScalars.filter { allowedCharacters.contains($0) }
        var string = String(String.UnicodeScalarView(filtered))
        
        if let commaIndex = string.firstIndex(of: ",") {
            let beforeComma = string[..<commaIndex]
            let afterComma = string[string.index(after: commaIndex)...]
                .prefix(2)
            string = String(beforeComma) + "," + String(afterComma)
        }
        
        return string
    }
}
#Preview {
    ScoreView()
}
