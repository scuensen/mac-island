import Foundation

@MainActor
final class WeatherWidgetModel: ObservableObject {
    @Published var temperature = ""
    @Published var condition   = ""
    @Published var icon        = "cloud"
    @Published var city        = ""
    @Published var isLoading   = false

    private var timer: Foundation.Timer?

    func startPolling() {
        Task { await fetch() }
        timer = Foundation.Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { await self?.fetch() }
        }
    }

    func stopPolling() { timer?.invalidate(); timer = nil }

    func fetch() async {
        isLoading = true
        defer { isLoading = false }

        // wttr.in — free, no API key, uses IP geolocation
        guard let url = URL(string: "https://wttr.in/?format=j1&m") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONDecoder().decode(WttrResponse.self, from: data)
            if let current = json.current_condition.first,
               let area    = json.nearest_area.first?.areaName.first?.value {
                temperature = "\(current.temp_C)°C"
                condition   = current.weatherDesc.first?.value ?? ""
                icon        = sfIcon(for: current.weatherCode)
                city        = area
            }
        } catch {}
    }

    private func sfIcon(for code: String) -> String {
        switch code {
        case "113": return "sun.max.fill"
        case "116": return "cloud.sun.fill"
        case "119", "122": return "cloud.fill"
        case "143", "248", "260": return "cloud.fog.fill"
        case "176", "293", "296": return "cloud.drizzle.fill"
        case "179", "323", "326": return "cloud.snow.fill"
        case "200", "386", "389": return "cloud.bolt.fill"
        case "230", "329", "332", "335", "338": return "snowflake"
        case "266", "299", "302": return "cloud.rain.fill"
        case "305", "308": return "cloud.heavyrain.fill"
        default: return "cloud.fill"
        }
    }
}

private struct WttrResponse: Decodable {
    let current_condition: [CurrentCondition]
    let nearest_area: [NearestArea]
}

private struct CurrentCondition: Decodable {
    let temp_C: String
    let weatherCode: String
    let weatherDesc: [ValueWrapper]
}

private struct NearestArea: Decodable {
    let areaName: [ValueWrapper]
}

private struct ValueWrapper: Decodable {
    let value: String
}
