import SwiftUI

struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(category.emoji))
                    .frame(width: 22, height: 22)
                    .padding(.trailing, 16)
                
                Text(category.name)
                    .font(.system(size: 17, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
            return viewDimensions[.listRowSeparatorLeading] + 46
        }
    }
}
