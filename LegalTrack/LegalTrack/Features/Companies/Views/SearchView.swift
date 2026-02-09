import SwiftUI

struct LegacySearchView: View {
    @State private var searchText = ""

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                TextField("Search", text: $searchText)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)

                Spacer()

                Text("Search results will appear here")
                    .foregroundStyle(.secondary)
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
