import Foundation

/// Fetches and parses a podcast RSS feed, returning the list of episodes.
final class RSSParser: NSObject, XMLParserDelegate {

    // ── Result ───────────────────────────────────────────────────────────
    private(set) var episodes: [PodcastEpisode] = []

    // ── Per-item scratch ─────────────────────────────────────────────────
    private var inItem          = false
    private var currentElement  = ""
    private var charBuffer      = ""

    private var itemTitle       = ""
    private var itemAudioURL    : URL?
    private var itemDuration    = ""
    private var itemPubDate     = ""

    // MARK: – Public

    /// Fetches `feedURL`, parses it, and returns episodes newest-first.
    static func fetch(feedURL: URL) async throws -> [PodcastEpisode] {
        let (data, response) = try await URLSession.shared.data(from: feedURL)
        guard (response as? HTTPURLResponse)?.statusCode != 404 else {
            throw URLError(.badServerResponse)
        }
        let p = RSSParser()
        let xml = XMLParser(data: data)
        xml.delegate = p
        xml.parse()
        return p.episodes
    }

    // MARK: – XMLParserDelegate

    func parser(_ parser: XMLParser,
                didStartElement element: String,
                namespaceURI: String?,
                qualifiedName _: String?,
                attributes attrs: [String: String] = [:]) {
        currentElement = element
        charBuffer = ""

        if element == "item" || element == "entry" {
            inItem       = true
            itemTitle    = ""
            itemAudioURL = nil
            itemDuration = ""
            itemPubDate  = ""
        }

        // <enclosure url="..." type="audio/..."/>
        if inItem && element == "enclosure",
           let urlStr = attrs["url"],
           let type   = attrs["type"], type.hasPrefix("audio"),
           let url    = URL(string: urlStr) {
            itemAudioURL = url
        }

        // <media:content url="..." type="audio/..."/>
        if inItem && element == "media:content",
           let urlStr = attrs["url"],
           let type   = attrs["type"], type.hasPrefix("audio"),
           let url    = URL(string: urlStr) {
            itemAudioURL = url
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        charBuffer += string
    }

    func parser(_ parser: XMLParser,
                didEndElement element: String,
                namespaceURI: String?,
                qualifiedName _: String?) {
        let text = charBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        if inItem {
            switch element {
            case "title":
                if itemTitle.isEmpty { itemTitle = text }
            case "itunes:duration":
                itemDuration = text
            case "pubDate", "published":
                itemPubDate = text
            default:
                break
            }
        }

        if element == "item" || element == "entry" {
            if let url = itemAudioURL, !itemTitle.isEmpty {
                episodes.append(PodcastEpisode(
                    title:    itemTitle,
                    audioURL: url,
                    duration: itemDuration,
                    pubDate:  itemPubDate
                ))
            }
            inItem = false
        }

        charBuffer = ""
    }
}
