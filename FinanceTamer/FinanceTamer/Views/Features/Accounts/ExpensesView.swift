import SwiftUI

struct ExpensesView: View {
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()
    @EnvironmentObject var currencyService: CurrencyService
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    @State private var showNewExpense = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                TransactionsListView(title: "Расходы сегодня")
                    .environmentObject(transactionsViewModel)
                    .onAppear {
                        transactionsViewModel.switchDirection(to: .outcome)
                    }
                
                if transactionsViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                        .zIndex(1)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showNewExpense = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 28)
                                    .frame(width: 56, height: 56)
                                    .foregroundStyle(Color.accentColor)
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.bottom, 28)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ExpensesHistoryView()
                    } label: {
                        Image("time")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(Color.navigation)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showNewExpense) {
            NewExpensesView()
                .environmentObject(currencyService)
                .environmentObject(transactionsViewModel)
                .onDisappear {
                    Task {
                        await transactionsViewModel.loadTransactions()
                    }
                }
        }
    }
}

#Preview {
    ExpensesView()
}
