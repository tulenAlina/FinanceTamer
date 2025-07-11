import SwiftUI

struct IncomeView: View {
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()
    @EnvironmentObject var currencyService: CurrencyService
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                TransactionsListView(title: "Доходы сегодня")
                    .environmentObject(transactionsViewModel)
                    .onAppear {
                        transactionsViewModel.switchDirection(to: .income)
                    }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink {
                            NewIncomeView()
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
                        IncomeHistoryView()
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
    IncomeView()
}
