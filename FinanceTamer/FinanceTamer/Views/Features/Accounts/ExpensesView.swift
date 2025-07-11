import SwiftUI

struct ExpensesView: View {
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()
    @EnvironmentObject var currencyService: CurrencyService
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                TransactionsListView(title: "Расходы сегодня")
                    .environmentObject(transactionsViewModel)
                    .onAppear {
                        transactionsViewModel.switchDirection(to: .outcome)
                    }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink {
                            NewExpensesView()
                                .environmentObject(currencyService)
                                .environmentObject(transactionsViewModel)
                                .onDisappear {
                                    Task {
                                        await transactionsViewModel.loadTransactions()
                                    }
                                }
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
    }
}

#Preview {
    ExpensesView()
}
