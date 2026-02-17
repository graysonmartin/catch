import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query(sort: \Cat.name) private var cats: [Cat]

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if cats.isEmpty {
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "No Cats Collected",
                        subtitle: "Cats you encounter will appear here."
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(cats) { cat in
                                NavigationLink(value: cat) {
                                    CatCardView(cat: cat)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle("Collection")
            .navigationDestination(for: Cat.self) { cat in
                CatProfileView(cat: cat)
            }
        }
    }
}

struct CatCardView: View {
    let cat: Cat

    var body: some View {
        VStack(spacing: 8) {
            CatPhotoView(photoData: cat.photos.first, size: 120)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 4) {
                HStack {
                    Text(cat.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CatchTheme.textPrimary)
                        .lineLimit(1)
                    if cat.isOwned {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(CatchTheme.primary)
                    }
                }

                Text("\(cat.encounters.count) encounter\(cat.encounters.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .padding(12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
