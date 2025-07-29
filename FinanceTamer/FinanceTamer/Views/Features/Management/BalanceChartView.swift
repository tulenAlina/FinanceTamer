import SwiftUI
import Charts

struct BalanceChartView: View {
    let data: [BalanceData]
    @State private var selectedDate: Date?
    @State private var selectedBalance: Decimal?
    @State private var touchLocation: CGPoint = .zero
    @State private var chartFrame: CGRect = .zero
    
    private var chartWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 32
        return screenWidth
    }
    
    private func shouldShowDateLabel(for date: Date) -> Bool {
        guard !data.isEmpty else { return false }
        
        let firstDate = data.first?.date ?? date
        let lastDate = data.last?.date ?? date
        
        if Calendar.current.isDate(date, inSameDayAs: firstDate) || 
           Calendar.current.isDate(date, inSameDayAs: lastDate) {
            return true
        }
        
        let daysFromStart = Calendar.current.dateComponents([.day], from: firstDate, to: date).day ?? 0
        return daysFromStart % 5 == 0
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            ZStack {
                Chart(data) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Balance", item.balance.doubleValue)
                    )
                    .foregroundStyle(item.isPositive ? Color.green : Color.red)
                    .cornerRadius(2)
                }
                .chartYScale(domain: 0...(data.map { $0.balance.doubleValue }.max() ?? 0) * 1.2)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        if let date = value.as(Date.self) {
                            let shouldShowLabel = shouldShowDateLabel(for: date)
                            if shouldShowLabel {
                                let isLastDay = Calendar.current.isDate(date, inSameDayAs: data.last?.date ?? date)
                                AxisValueLabel {
                                    Text(date, format: .dateTime.day().month(.twoDigits))
                                        .font(.system(size: 9))
                                }.offset(x: isLastDay ? -20 : 0)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisTick()
                    }
                }
                .chartOverlay { proxy in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let xPosition = value.location.x
                                    touchLocation = value.location
                                    
                                    if let date = proxy.value(atX: xPosition, as: Date.self) {
                                        selectedDate = date
                                        if let balanceData = data.first(where: { 
                                            Calendar.current.isDate($0.date, inSameDayAs: date) 
                                        }) {
                                            selectedBalance = balanceData.balance
                                        } else {
                                            selectedBalance = nil
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    selectedDate = nil
                                    selectedBalance = nil
                                }
                        )
                }
                .frame(height: 200)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                chartFrame = geometry.frame(in: .local)
                            }
                    }
                )
                
                if selectedDate != nil {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .position(
                            x: touchLocation.x + 16,
                            y: 100
                        )
                        .zIndex(1000)
                }
                
                if let selectedDate = selectedDate, let selectedBalance = selectedBalance {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Дата: \(formatDate(selectedDate))")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("Баланс: \(formatBalance(selectedBalance))")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .position(
                        x: min(touchLocation.x + 80, UIScreen.main.bounds.width - 100),
                        y: max(touchLocation.y - 40, 50)
                    )
                }
            }
            
            Rectangle()
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .foregroundColor(.clear)
        }
        .frame(height: 216)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func formatBalance(_ balance: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        return formatter.string(from: balance as NSDecimalNumber) ?? "0"
    }
}

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
}
