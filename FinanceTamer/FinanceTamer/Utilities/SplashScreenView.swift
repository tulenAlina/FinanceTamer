import SwiftUI
import LottieUI

struct SplashScreenView: View {
    @EnvironmentObject var transactionsVM: TransactionsViewModel
    @EnvironmentObject var currencyService: CurrencyService
    
    @State private var isActive = true // Анимация активна сразу
    @State private var animationFinished = false
    @State private var showContent = false
    
    var body: some View {
        Group {
            if showContent {
                TabBarView()
                    .transition(.opacity)
            } else {
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    LottieView(
                        name: "animation",
                        loopMode: .playOnce,
                        animationSpeed: 1.0
                    ) {
                        // Анимация завершена, переходим к основному интерфейсу
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showContent = true
                        }
                    }
                    .frame(width: 300, height: 300)
                }
                .opacity(isActive ? 1 : 0)
            }
        }
    }
} 