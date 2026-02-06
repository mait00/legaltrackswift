import SwiftUI

struct LegacySearchView: View {
    @State private var searchText = ""

    var body: some View {
        ZStack {
            LiquidGlassBackground()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                TextField("Search", text: $searchText)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                Spacer()

                Text("Search results will appear here")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.headline)

                Spacer()
            }
            .padding()
        }
    }
}

struct LegacySearchView_Previews: PreviewProvider {
    static var previews: some View {
        LegacySearchView()
    }
}
