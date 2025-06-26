import SwiftUI

struct ScoreView: View {
    @StateObject private var viewModel = ScoreViewModel()
    @State private var isEditing = false
    @State private var showCurrencyPicker = false
    @State private var balanceText: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Balance row
                    HStack {
                        Text("💰 Баланс")
                        Spacer()
                        if isEditing {
                            TextField("", text: $balanceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onAppear {
                                    balanceText = viewModel.balanceString
                                }
                                .foregroundColor(isEditing ? Color(white: 0.5) : .primary)
                        } else {
                            Text(viewModel.balanceString)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isEditing {
                            // Keyboard will show automatically from TextField
                        }
                    }
                    .listRowBackground(isEditing ? Color(.systemBackground) : Color.accentColor)
                    
                    // Currency row
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
                            .transition(.opacity)
                        
                        CurrencyPickerView(selectedCurrency: $viewModel.currency)
                            .transition(.move(edge: .bottom))
                    }
                }
                .animation(.easeInOut, value: showCurrencyPicker))
            .onAppear {
                viewModel.loadAccount()
            }
            .gesture(
                DragGesture().onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
        }
    }
}

#Preview {
    ScoreView()
}
