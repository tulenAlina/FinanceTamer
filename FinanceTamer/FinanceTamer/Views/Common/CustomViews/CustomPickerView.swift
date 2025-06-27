import SwiftUI

struct CustomPickerView: View {
    @Binding var date: Date
    
    var body: some View {
        HStack(spacing: 2) {
            Text(date.formatted(.dateTime.day().month().year()))
                .font(.system(size: 17, weight: .regular))
        }
        .padding(.horizontal, 12)
        .foregroundColor(.black)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .foregroundColor(.accentColor)
                .opacity(0.2)
                .padding(.vertical, -7)
        )
        .overlay {
            DatePicker(selection: $date, displayedComponents: .date) {}
                .labelsHidden()
                .colorMultiply(.clear)
        }
    }
}
