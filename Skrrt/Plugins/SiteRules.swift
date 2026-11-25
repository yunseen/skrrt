import Observation
import SwiftUI
import WebKit

/// Elements you chose to hide on a site, like the element picker of content blockers.
@MainActor
@Observable
final class SiteRules {
    private(set) var rules: [String: [String]] = [:]
    @ObservationIgnored var onChange: (@MainActor () -> Void)?

    init() {
        load()
    }

    var hosts: [String] {
        rules.keys.sorted()
    }

    var totalCount: Int {
        rules.values.reduce(0) { $0 + $1.count }
    }

    func selectors(for host: String) -> [String] {
        let clean = Self.clean(host)
        return rules.filter { clean == $0.key || clean.hasSuffix("." + $0.key) }.flatMap(\.value)
    }

    func add(_ selector: String, host: String) {
        let key = Self.clean(host)
        var list = rules[key] ?? []
        guard !selector.isEmpty, !list.contains(selector) else { return }
        list.append(selector)
        rules[key] = list
        persist()
    }

    func remove(_ selector: String, host: String) {
        let key = Self.clean(host)
        rules[key]?.removeAll { $0 == selector }
        if rules[key]?.isEmpty == true { rules[key] = nil }
        persist()
    }

    func removeAll(host: String) {
        rules[Self.clean(host)] = nil
        persist()
    }

    static func clean(_ host: String) -> String {
        host.lowercased().replacingOccurrences(of: "www.", with: "")
    }

    /// One script with every rule. It checks the address itself, so it can stay in place for all pages.
    var script: WKUserScript? {
        guard !rules.isEmpty else { return nil }
        let data = (try? JSONSerialization.data(withJSONObject: rules, options: [.withoutEscapingSlashes])) ?? Data("{}".utf8)
        let map = String(decoding: data, as: UTF8.self)
        let source = """
        (function(){
        var R=\(map);
        var h=location.hostname.replace(/^www\\./,'');
        var sel=[];
        for(var k in R){if(h===k||h.slice(-(k.length+1))==='.'+k)sel=sel.concat(R[k]);}
        if(!sel.length)return;
        function put(){
          var parent=document.head||document.documentElement;
          if(!parent)return false;
          var s=document.createElement('style');
          s.setAttribute('data-skrrt','hidden');
          s.textContent=sel.join(',')+'{display:none!important}';
          parent.appendChild(s);
          return true;
        }
        if(!put())document.addEventListener('DOMContentLoaded',put,{once:true});
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: PluginRuntime.world)
    }

    // MARK: The element picker

    /// Starts the picker on the current page. Tap an element, then confirm to hide it.
    static func pickerSource(language: String) -> String {
        let ru = language == "ru"
        let hint = ru ? "Нажмите на элемент, который нужно скрыть" : "Tap the element you want to hide"
        let hide = ru ? "Скрыть" : "Hide"
        let larger = ru ? "Шире" : "Larger"
        let cancel = ru ? "Отмена" : "Cancel"
        return """
        (function(){
        if(window.__skrrtPicker){window.__skrrtPicker.stop();}
        var chosen=null,box=document.createElement('div'),top=document.createElement('div'),bar=document.createElement('div');
        var ui=[box,top,bar];
        box.style.cssText='position:fixed;pointer-events:none;z-index:2147483645;border:2px solid #0a84ff;background:rgba(10,132,255,.18);border-radius:4px;display:none';
        top.textContent=\(PluginRuntime.json(hint));
        top.style.cssText='position:fixed;top:12px;left:50%;transform:translateX(-50%);max-width:86%;z-index:2147483647;padding:10px 16px;border-radius:999px;background:rgba(20,20,24,.9);color:#fff;font:600 14px -apple-system,sans-serif;text-align:center';
        bar.style.cssText='position:fixed;left:50%;bottom:30px;transform:translateX(-50%);z-index:2147483647;display:none;gap:8px;padding:8px;border-radius:999px;background:rgba(20,20,24,.92)';
        function button(text,color,fn){
          var b=document.createElement('button');
          b.textContent=text;
          b.style.cssText='border:0;border-radius:999px;padding:10px 18px;font:700 15px -apple-system,sans-serif;color:#fff;background:'+color;
          b.addEventListener('click',function(e){e.preventDefault();e.stopPropagation();fn();});
          return b;
        }
        function ours(n){return ui.indexOf(n)>-1||bar.contains(n);}
        function selectorFor(el){
          function unique(s){try{return document.querySelectorAll(s).length===1;}catch(e){return false;}}
          var parts=[],node=el;
          while(node&&node.nodeType===1&&node!==document.documentElement&&parts.length<6){
            var s=node.tagName.toLowerCase();
            if(node.id&&/^[A-Za-z][\\w-]*$/.test(node.id)){parts.unshift('#'+node.id);if(unique(parts.join(' > ')))break;}
            var cls=[].slice.call(node.classList).filter(function(c){return /^[A-Za-z][\\w-]{1,30}$/.test(c)&&!/\\d{3,}/.test(c);}).slice(0,2);
            if(cls.length)s+='.'+cls.join('.');
            var parent=node.parentElement;
            if(parent&&!cls.length){
              var same=[].filter.call(parent.children,function(c){return c.tagName===node.tagName;});
              if(same.length>1)s+=':nth-of-type('+(same.indexOf(node)+1)+')';
            }
            parts.unshift(s);
            if(unique(parts.join(' > ')))break;
            node=node.parentElement;
          }
          return parts.join(' > ');
        }
        function show(el){
          chosen=el;
          var r=el.getBoundingClientRect();
          box.style.display='block';
          box.style.left=r.left+'px';box.style.top=r.top+'px';box.style.width=r.width+'px';box.style.height=r.height+'px';
          bar.style.display='flex';
        }
        function onTap(e){
          if(ours(e.target))return;
          e.preventDefault();e.stopPropagation();
          show(e.target);
        }
        function stop(){
          document.removeEventListener('click',onTap,true);
          ui.forEach(function(n){if(n.parentNode)n.parentNode.removeChild(n);});
          window.__skrrtPicker=null;
        }
        bar.appendChild(button(\(PluginRuntime.json(hide)),'#ff453a',function(){
          if(!chosen)return;
          var selector=selectorFor(chosen);
          var target=chosen;
          stop();
          var h=window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.skrrt;
          if(h&&selector){h.postMessage({op:'hide',selector:selector}).then(function(){target.style.setProperty('display','none','important');});}
        }));
        bar.appendChild(button(\(PluginRuntime.json(larger)),'#3a3a3c',function(){
          if(chosen&&chosen.parentElement&&chosen.parentElement!==document.body)show(chosen.parentElement);
        }));
        bar.appendChild(button(\(PluginRuntime.json(cancel)),'#3a3a3c',stop));
        document.documentElement.appendChild(box);
        document.documentElement.appendChild(top);
        document.documentElement.appendChild(bar);
        document.addEventListener('click',onTap,true);
        window.__skrrtPicker={stop:stop};
        })();
        """
    }

    // MARK: Storage

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("hidden-elements.json")
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL), let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            rules = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(rules) {
            try? data.write(to: fileURL, options: .atomic)
        }
        onChange?()
    }
}
