import SwiftUI

struct TabBarView: View {
    
    var body: some View {
        TabView() {
            ExpensesView()
                .tabItem {
                    tabItem(imageName: "expensesTab", title: "Расходы")
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white, for: .tabBar)
            
            IncomeView()
                .tabItem {
                    tabItem(imageName: "incomeTab", title: "Доходы")
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white, for: .tabBar)
            
            ScoreView()
                .tabItem {
                    tabItem(imageName: "scoreTab", title: "Счет")
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white, for: .tabBar)
            
            CategoriesView()
                .tabItem {
                    tabItem(imageName: "articlesTab", title: "Статьи")
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white, for: .tabBar)
            
            SettingsView()
                .tabItem {
                    tabItem(imageName: "settingsTab", title: "Настройки")
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white, for: .tabBar)
        }
    }
    
    @ViewBuilder
    func tabItem(imageName: String, title: String) -> some View {
        VStack {
            Image(imageName)
                .renderingMode(.template)
            Text(title)
        }
    }
}

#Preview {
    TabBarView()
}
