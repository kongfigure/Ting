import SwiftUI

struct TingHeader: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Text("Ting 聽")
                .font(.headline)
                .foregroundStyle(.tint)
        }
    }
}
