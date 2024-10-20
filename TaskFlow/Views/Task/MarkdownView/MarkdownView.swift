import SwiftUI
import MarkdownUI

struct MarkdownView: View {
    let markdownContent: String
    
    var body: some View {
        ScrollView {
            Markdown(markdownContent)
                .padding()
        }
        .navigationTitle("Markdown")
    }
}

struct MarkdownView_Previews: PreviewProvider {
    static var previews: some View {
        MarkdownView(markdownContent: "# Hello, Markdown!\n\nThis is a sample Markdown content.")
    }
}
