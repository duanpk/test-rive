import RiveRuntime
import SwiftUI

struct RiveDemoView: View {
//    @State private var userInput: String = ""
//    @State private var rvm = RiveViewModel(fileName: "dynamic-text")
//    @State private var rvm2 = RiveViewModel(fileName: "Memory Match")
//    @StateObject private var rvEvent = RiveEventsVMExample()
//
//    var body: some View {
//        VStack(spacing: 20) {
//            rvm2.view()
//            rvEvent.view()
//            Text("Enter text:")
//                .font(.headline)
//            TextField("Enter text...", text: $userInput)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//                .onChange(
//                    of: userInput,
//                    perform: { newValue in
//                        if !newValue.isEmpty {
//                            try! rvm.setTextRunValue("MyText", textValue: userInput)
//                        }
//                    })
//            rvm.view()
//        }
//    }
    var dismiss: () -> Void = {}
        @StateObject private var rvm2 = RiveEventsVMExample2()
        @StateObject private var rvm = RiveEventsVMExample()

        var body: some View {
            VStack {
                rvm.view()
                rvm2.view()
            }
        }
}

#Preview {
    RiveDemoView()
}

class RiveEventsVMExample2: RiveViewModel {
    @Published var eventText = ""

    init() {
        super.init(fileName: "FPS")
    }

    func view() -> some View {
        return super.view().frame(width: 400, height: 400, alignment: .center)
    }

    @objc func onRiveEventReceived(onRiveEvent riveEvent: RiveEvent) {
        print("dbg: Rive event received: \(riveEvent.name())")
        debugPrint("Event Name: \(riveEvent.name())")
        debugPrint("Event Type: \(riveEvent.type())")
        if let openUrlEvent = riveEvent as? RiveOpenUrlEvent {
            debugPrint("Open URL Event Properties: \(openUrlEvent.properties())")
            if let url = URL(string: openUrlEvent.url()) {
                #if os(iOS) || os(visionOS) || os(tvOS)
                UIApplication.shared.open(url)
                #else
                NSWorkspace.shared.open(url)
                #endif
            }
        } else if let generalEvent = riveEvent as? RiveGeneralEvent {
            let genEventProperties = generalEvent.properties();
            debugPrint("General Event Properites: \(genEventProperties)")
            if let msg = genEventProperties["message"] {
                eventText = msg as! String
            }
        }

    }
}

class RiveEventsVMExample: RiveViewModel {
    @Published var eventText = ""

    init() {
//        super.init(fileName: "rating_animation")
        super.init(fileName: "rating_animation_event")
    }

    func view() -> some View {
        return super.view()
    }

    // Subscribe to Rive events and this delegate will be invoked
    @objc func onRiveEventReceived(onRiveEvent riveEvent: RiveEvent) {
        print("dbg: Rive event received: \(riveEvent.name())")
        if let openUrlEvent = riveEvent as? RiveOpenUrlEvent {
            if let url = URL(string: openUrlEvent.url()) {
                #if os(iOS)
                UIApplication.shared.open(url)
                #else
                NSWorkspace.shared.open(url)
                #endif
            }
        } else if let generalEvent = riveEvent as? RiveGeneralEvent {
            let genEventProperties = generalEvent.properties();
            if let msg = genEventProperties["message"] {
                eventText = msg as! String
            }
        }

    }
}
