import SwiftUI
import lqPerf

struct ContentView: View {
    @State private var counter = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("LQPerf Sample")
                .font(.title2)

            Text("Counter: \(counter)")

            Button("Increase") {
                counter += 1
            }

            Button("Simulate Work") {
                heavyWork()
            }

            Button("Send Demo Request") {
                sendDemoRequest()
            }
        }
        .padding(24)
        .onAppear {
            LQPerf.shared.start()
        }
    }

    private func heavyWork() {
        var sum = 0
        for i in 0..<2_000_000 {
            sum += i
        }
        print(sum)
    }

    private func sendDemoRequest() {
        guard let url = URL(string: "https://httpbin.org/get") else { return }
        let task = URLSession.shared.dataTask(with: url) { _, _, error in
            if let error {
                print("Demo request error: \(error)")
            } else {
                print("Demo request success")
            }
        }
        task.resume()
    }
}
