import Combine
import SwiftUI

class SharedMarqueeState: ObservableObject {
    @Published var isDragging = false
    @Published var dragTranslation: CGFloat = 0

    func dragChanged(_ value: DragGesture.Value) {
        isDragging = true
        dragTranslation = value.translation.width
    }

    func dragEnded(_ value: DragGesture.Value) {
        isDragging = false
        dragTranslation = 0
    }
}

struct MarqueeModel {
    var contentWidth: CGFloat?
    var offset: CGFloat = 0
    var dragStartOffset: CGFloat?
    var dragTranslation: CGFloat = 0
    var currentVelocity: CGFloat = 0

    var previousTick: Date = .now
    var targetVelocity: Double
    var spacing: CGFloat

    var sharedState: SharedMarqueeState?

    init(targetVelocity: Double, spacing: CGFloat) {
        self.targetVelocity = targetVelocity
        self.spacing = spacing
    }

    mutating func updatePosition(at time: Date) {
        let delta = time.timeIntervalSince(previousTick)
        defer { previousTick = time }
        currentVelocity += (targetVelocity - currentVelocity) * delta * 3

        if let shared = sharedState, shared.isDragging {
            if dragStartOffset == nil {
                dragStartOffset = offset
            }
            offset = dragStartOffset! + shared.dragTranslation
        } else if dragStartOffset != nil {
            dragStartOffset = nil
            dragTranslation = 0
        } else {
            offset -= delta * currentVelocity
        }

        if let width = contentWidth {
            offset.formTruncatingRemainder(dividingBy: width + spacing)  // meaning offset = offset % (width + spacing)
            while offset > 0 {
                offset -= width + spacing
            }
        }
    }
}

struct Marquee<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var containerWidth: CGFloat?
    @State private var model: MarqueeModel
    private var targetVelocity: Double
    private var spacing: CGFloat

    @ObservedObject var sharedState: SharedMarqueeState

    init(
        targetVelocity: Double,
        spacing: CGFloat = 10,
        sharedState: SharedMarqueeState,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self._model = .init(wrappedValue: MarqueeModel(targetVelocity: targetVelocity, spacing: spacing))
        self.targetVelocity = targetVelocity
        self.spacing = spacing
        self.sharedState = sharedState
    }

    var numOfExtraContent: Int {
        let contentPlusSpacing = ((model.contentWidth ?? 0) + model.spacing)
        guard contentPlusSpacing != 0 else { return 1 }
        return Int(((containerWidth ?? 0) / contentPlusSpacing).rounded(.up))
    }

    var body: some View {
        TimelineView(.animation) { context in
            HStack(spacing: model.spacing) {
                HStack(spacing: model.spacing) {
                    content
                }
                .measureWidth { model.contentWidth = $0 }
                ForEach(Array(0..<numOfExtraContent), id: \.self) { _ in
                    content
                        .border(.red)
                }
            }
            .offset(x: model.offset)
            .fixedSize()
            .onChange(of: context.date) { _, newDate in
                DispatchQueue.main.async {
                    model.sharedState = sharedState
                    model.updatePosition(at: newDate)
                }
            }
        }
        .measureWidth { containerWidth = $0 }
        .onAppear { model.previousTick = .now }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

struct MarqueeView: View {
    var velocity: CGFloat = 50
    let imageArray: [ImageModel] = [
        .init(
            text: "1",
            imageURL: URL(string: "https://picsum.photos/200")),
        .init(
            // text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
            text: "2",
            imageURL: URL(string: "https://picsum.photos/200")),
        .init(
            text: "3",
            imageURL: URL(string: "https://picsum.photos/200")),
        .init(
            text: "4",
            imageURL: URL(string: "https://picsum.photos/200"))
    ]

    @StateObject private var sharedState = SharedMarqueeState()

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                Marquee(targetVelocity: velocity, sharedState: sharedState) {
                    ForEach(imageArray) { item in
                        HStack(alignment: .top) {
                            if let url = item.imageURL {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 24, height: 24)
                                }
                            }
                            Text(item.text)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: 200, alignment: .leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        // .padding(.top, CGFloat.random(in: -10...20))
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    sharedState.dragChanged(value)
                }
                .onEnded { value in
                    sharedState.dragEnded(value)
                }
        )
    }
}

struct ImageModel: Identifiable {
    var id: UUID = UUID()
    var text: String
    var imageURL: URL?
}

extension View {
    func measureWidth(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                let width = proxy.size.width
                Color.clear
                    .onAppear {
                        DispatchQueue.main.async {
                            onChange(width)
                        }
                    }
                    .onChange(of: width) { _, newValue in
                        onChange(newValue)
                    }
            }
        }
    }
}

#Preview {
    MarqueeView()
}
