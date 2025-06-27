import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: Currency
    @EnvironmentObject var currencyService: CurrencyService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            Text("Валюта")
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            // Разделитель
            Divider()
            
            // Варианты валют
            currencyRow("Российский рубль ₽", currency: .rub)
            Divider()
            currencyRow("Американский доллар $", currency: .usd)
            Divider()
            currencyRow("Евро €", currency: .eur)
        }
        .frame(width: UIScreen.main.bounds.width - 40)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground).opacity(0.7))
                .shadow(radius: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 40)
    }
    
    private func currencyRow(_ name: String, currency: Currency) -> some View {
            Button(action: {
                selectedCurrency = currency
                currencyService.currentCurrency = currency
                dismiss()
            }) {
                HStack {
                    Spacer()
                    Text(name)
                        .font(.system(size: 17))
                        .foregroundColor(Color.navigation)
                    Spacer()
                    
                    if currency == selectedCurrency {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color.navigation)
                            .padding(.leading, 8)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
        }
}
#Preview {
    ScoreView()
}
