import SwiftUI
import WidgetKit

@main
struct SpygameLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.2, *) {
            RoundActivityWidget()
        }
    }
}
