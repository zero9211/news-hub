import Foundation

struct PodcastEpisode: Identifiable {
    let id        = UUID()
    let title     : String
    let audioURL  : URL
    let duration  : String   // e.g. "01:23:45" or "3605" seconds
    let pubDate   : String
}
