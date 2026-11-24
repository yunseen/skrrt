import WebKit

@MainActor
final class ContentBlocker {
    private var ruleList: WKContentRuleList?

    func prepare() async {
        guard
            let url = Bundle.main.url(forResource: "blocklist", withExtension: "json"),
            let rules = try? String(contentsOf: url, encoding: .utf8)
        else { return }
        ruleList = try? await WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "skrrt.blocklist",
            encodedContentRuleList: rules
        )
    }

    func apply(to tab: Tab, enabled: Bool) {
        let controller = tab.webView.configuration.userContentController
        controller.removeAllContentRuleLists()
        if enabled, let ruleList {
            controller.add(ruleList)
        }
    }
}
