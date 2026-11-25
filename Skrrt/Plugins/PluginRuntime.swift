import Foundation
import WebKit

/// Builds the user scripts WebKit injects into every page.
///
/// Like content scripts in Chrome, plugins run in an isolated world: they share the page's DOM but not
/// its JavaScript variables, and the page cannot reach them or the bridge to the app.
/// A shared prelude defines the `Skrrt` API once. Each enabled plugin is then wrapped in its own
/// function scope with an address filter, its settings and its per-site switches.
enum PluginRuntime {
    static let apiVersion = "1.3"
    static let world = WKContentWorld.world(name: "SkrrtPlugins")

    @MainActor
    static func scripts(for plugins: [Plugin], rules: SiteRules, language: String) -> [WKUserScript] {
        var result: [WKUserScript] = []
        let enabled = plugins.filter(\.isEnabled)
        if !enabled.isEmpty {
            result.append(WKUserScript(source: prelude, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: world))
            if enabled.contains(where: \.inPage) {
                result.append(WKUserScript(source: prelude, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: .page))
            }
            for plugin in enabled {
                result.append(WKUserScript(
                    source: wrap(plugin, language: language),
                    injectionTime: plugin.runsAtStart ? .atDocumentStart : .atDocumentEnd,
                    forMainFrameOnly: true,
                    in: plugin.inPage ? .page : world
                ))
            }
        }
        if let hidden = rules.script {
            result.append(hidden)
        }
        return result
    }

    static func wrap(_ plugin: Plugin, language: String) -> String {
        let info = json([
            "id": plugin.id,
            "name": plugin.name.text("en"),
            "version": plugin.version,
            "lang": language,
            "options": plugin.effectiveValues.mapValues(\.jsonObject),
            "blocked": plugin.blockedHosts
        ])
        let body: String
        switch plugin.kind {
        case .style:
            body = "Skrrt.addStyle(\(json(plugin.code)));"
        case .script:
            body = plugin.code
        }
        return """
        (function(){try{
        var P=\(info);
        if(!window.__skrrtMatch(\(json(plugin.matches)),\(json(plugin.excludes)),P.blocked))return;
        var Skrrt=window.__skrrtMake(P),skrrt=Skrrt;
        (function(Skrrt,skrrt){
        \(body)
        })(Skrrt,skrrt);
        }catch(e){console.error('[Skrrt plugin '+(typeof P!=='undefined'?P.name:'?')+']',e);}})();
        """
    }

    static func json(_ value: Any) -> String {
        if let text = value as? String {
            guard let data = try? JSONSerialization.data(withJSONObject: [text], options: [.withoutEscapingSlashes]),
                  let string = String(data: data, encoding: .utf8) else { return "\"\"" }
            return String(string.dropFirst().dropLast())
        }
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.withoutEscapingSlashes]),
              let string = String(data: data, encoding: .utf8) else { return "null" }
        return string
    }

    // swiftlint:disable line_length
    static let prelude = ##"""
    (function(){
    if(window.__skrrtMake)return;
    var sheets={};
    function esc(s){return String(s).replace(/[.+?^${}()|[\]\\]/g,'\\$&');}
    function glob(p){return new RegExp('^'+esc(p).replace(/\*/g,'.*')+'$','i');}
    function bareHost(){return location.hostname.replace(/^www\./,'');}
    function matchOne(p){
      p=String(p).trim();
      if(!p)return false;
      if(p==='*'||p==='<all_urls>')return true;
      if(/^[a-z][a-z0-9+.-]*:\/\//i.test(p))return glob(p).test(location.href);
      if(p.indexOf('/')>-1)return glob(p.replace(/^www\./,'')).test(bareHost()+location.pathname+location.search);
      var h=bareHost();p=p.replace(/^www\./,'').replace(/^\*\./,'');
      return h===p||h.slice(-(p.length+1))==='.'+p;
    }
    window.__skrrtMatch=function(inc,exc,blocked){
      if((blocked||[]).some(matchOne))return false;
      var ok=!inc||!inc.length||inc.some(matchOne);
      return ok&&!(exc||[]).some(matchOne);
    };
    window.__skrrtMake=function(P){
      var prefix='skrrt:'+P.id+':';
      var S={};
      var handler=window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.skrrt;
      S.version='1.3';
      S.plugin={id:P.id,name:P.name,version:P.version};
      S.lang=P.lang||'en';
      S.host=bareHost();
      S.isDark=!!(window.matchMedia&&matchMedia('(prefers-color-scheme: dark)').matches);
      S.options={
        get:function(key,fallback){return Object.prototype.hasOwnProperty.call(P.options,key)?P.options[key]:fallback;},
        all:function(){return JSON.parse(JSON.stringify(P.options));}
      };
      S.log=function(){var a=[].slice.call(arguments);a.unshift('[Skrrt:'+P.name+']');console.log.apply(console,a);};
      S.ready=function(fn){
        if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',function(){fn();},{once:true});
        else fn();
      };
      S.matches=function(pattern){return matchOne(pattern);};
      S.removeStyle=function(name){
        var key=P.id+':'+(name||'main'),rec=sheets[key];
        if(!rec)return;
        if(rec.sheet)document.adoptedStyleSheets=document.adoptedStyleSheets.filter(function(s){return s!==rec.sheet;});
        if(rec.el&&rec.el.parentNode)rec.el.parentNode.removeChild(rec.el);
        delete sheets[key];
      };
      S.addStyle=function(css,name){
        name=name||'main';
        S.removeStyle(name);
        var key=P.id+':'+name;
        var parent=document.head||document.documentElement;
        if(parent){
          var el=document.createElement('style');
          el.setAttribute('data-skrrt',key);
          el.textContent=css;
          parent.appendChild(el);
          if(el.sheet){sheets[key]={el:el};return el;}
          el.remove();
        }
        try{
          var sheet=new CSSStyleSheet();
          sheet.replaceSync(css);
          document.adoptedStyleSheets=document.adoptedStyleSheets.concat([sheet]);
          sheets[key]={sheet:sheet};
          return sheet;
        }catch(e){}
        if(!parent){document.addEventListener('DOMContentLoaded',function(){S.addStyle(css,name);},{once:true});}
        return null;
      };
      S.hide=function(selector){return S.addStyle(selector+'{display:none!important}','hide:'+selector);};
      S.observe=function(selector,callback){
        var seen=new WeakSet();
        function visit(node){
          if(seen.has(node))return;
          seen.add(node);
          try{callback(node);}catch(e){console.error(e);}
        }
        function scan(root){
          if(root.matches&&root.matches(selector))visit(root);
          if(root.querySelectorAll)root.querySelectorAll(selector).forEach(visit);
        }
        scan(document);
        var mo=new MutationObserver(function(list){
          list.forEach(function(m){m.addedNodes.forEach(function(n){if(n.nodeType===1)scan(n);});});
        });
        mo.observe(document,{childList:true,subtree:true});
        return mo;
      };
      S.remove=function(selector){
        function sweep(){document.querySelectorAll(selector).forEach(function(n){n.remove();});}
        sweep();
        return S.observe(selector,function(n){n.remove();});
      };
      S.waitFor=function(selector,timeout){
        timeout=timeout||10000;
        return new Promise(function(resolve,reject){
          var found=document.querySelector(selector);
          if(found)return resolve(found);
          var mo,t=setTimeout(function(){if(mo)mo.disconnect();reject(new Error('Timeout: '+selector));},timeout);
          mo=new MutationObserver(function(){
            var n=document.querySelector(selector);
            if(n){clearTimeout(t);mo.disconnect();resolve(n);}
          });
          mo.observe(document,{childList:true,subtree:true});
        });
      };
      S.click=function(selector){
        var n=document.querySelector(selector);
        if(n){n.click();return true;}
        return false;
      };
      S.every=function(ms,fn){return setInterval(fn,ms);};
      S.toast=function(text,ms){
        S.ready(function(){
          var t=document.createElement('div');
          t.textContent=text;
          t.style.cssText='position:fixed;left:50%;bottom:110px;transform:translateX(-50%);max-width:80%;padding:10px 16px;border-radius:999px;background:rgba(20,20,24,.88);color:#fff;font:600 14px -apple-system,sans-serif;z-index:2147483647;pointer-events:none;box-shadow:0 6px 24px rgba(0,0,0,.3)';
          document.documentElement.appendChild(t);
          setTimeout(function(){t.remove();},ms||2200);
        });
      };
      S.storage={
        get:function(k,d){try{var v=localStorage.getItem(prefix+k);return v===null?d:JSON.parse(v);}catch(e){return d;}},
        set:function(k,v){try{localStorage.setItem(prefix+k,JSON.stringify(v));}catch(e){}},
        remove:function(k){try{localStorage.removeItem(prefix+k);}catch(e){}}
      };
      S.fetch=function(url,init){
        if(!handler)return fetch(url,init);
        init=init||{};
        return handler.postMessage({op:'fetch',plugin:P.id,url:String(url),init:{method:init.method||'GET',headers:init.headers||{},body:init.body==null?null:String(init.body)}}).then(function(r){
          return {
            ok:r.ok,status:r.status,headers:r.headers||{},
            text:function(){return Promise.resolve(r.body);},
            json:function(){try{return Promise.resolve(JSON.parse(r.body));}catch(e){return Promise.reject(e);}}
          };
        });
      };
      S.copy=function(text){
        function fallback(){
          var t=document.createElement('textarea');
          t.value=text;document.body.appendChild(t);t.select();
          try{document.execCommand('copy');}catch(e){}
          t.remove();
        }
        if(navigator.clipboard&&navigator.clipboard.writeText){
          return navigator.clipboard.writeText(text).catch(fallback);
        }
        fallback();
        return Promise.resolve();
      };
      S.el=function(tag,attrs){
        var e=document.createElement(tag);
        attrs=attrs||{};
        for(var k in attrs){
          var v=attrs[k];
          if(k==='style'&&typeof v==='object')Object.assign(e.style,v);
          else if(k==='text')e.textContent=v;
          else if(k.slice(0,2)==='on'&&typeof v==='function')e.addEventListener(k.slice(2),v);
          else e.setAttribute(k,v);
        }
        for(var i=2;i<arguments.length;i++){
          var c=arguments[i];
          if(c==null)continue;
          e.appendChild(typeof c==='string'?document.createTextNode(c):c);
        }
        return e;
      };
      return S;
    };
    })();
    """##
}
