import SwiftUI

struct IncomeView: View {
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                TransactionsListView(
                    transactionsService: transactionsService,
                    categoriesService: categoriesService,
                    direction: .income,
                    title: "Доходы сегодня"
                )
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink {
                            NewIncomeView()
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
