import Foundation
import WebKit

/// Builds the user scripts WebKit injects into every page.
///
/// A shared prelude defines the `Skrrt` API once. Each enabled plugin is then wrapped in its own
/// function scope, with an address filter, so plugins cannot clash with each other or with the page.
enum PluginRuntime {
    static let apiVersion = "1.2"

    static func scripts(for plugins: [Plugin]) -> [WKUserScript] {
        let enabled = plugins.filter(\.isEnabled)
        guard !enabled.isEmpty else { return [] }
        var result = [WKUserScript(source: prelude, injectionTime: .atDocumentStart, forMainFrameOnly: true)]
        for plugin in enabled {
            result.append(WKUserScript(
                source: wrap(plugin),
                injectionTime: plugin.runsAtStart ? .atDocumentStart : .atDocumentEnd,
                forMainFrameOnly: true
            ))
        }
        return result
    }

    static func wrap(_ plugin: Plugin) -> String {
        let info = literal(["id": plugin.id, "name": plugin.name, "version": plugin.version])
        let matches = literal(plugin.matches)
        let excludes = literal(plugin.excludes)
        let body: String
        switch plugin.kind {
        case .style:
            body = "Skrrt.addStyle(\(literal(plugin.code)));"
        case .script:
            body = plugin.code
        }
        return """
        (function(){try{
        var P=\(info);
        if(!window.__skrrtMatch(\(matches),\(excludes)))return;
        var Skrrt=window.__skrrtMake(P),skrrt=Skrrt;
        (function(Skrrt,skrrt){
        \(body)
        })(Skrrt,skrrt);
        }catch(e){console.error('[Skrrt plugin '+(typeof P!=='undefined'?P.name:'?')+']',e);}})();
        """
    }

    private static func literal<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        guard let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) else {
            return "null"
        }
        return text
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
    window.__skrrtMatch=function(inc,exc){
      var ok=!inc||!inc.length||inc.some(matchOne);
      return ok&&!(exc||[]).some(matchOne);
    };
    window.__skrrtMake=function(P){
      var prefix='skrrt:'+P.id+':';
      var S={};
      S.version='1.2';
      S.plugin=P;
      S.host=bareHost();
      S.isDark=!!(window.matchMedia&&matchMedia('(prefers-color-scheme: dark)').matches);
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
        try{
          if(window.CSSStyleSheet&&document.adoptedStyleSheets!==undefined){
            var sheet=new CSSStyleSheet();
            sheet.replaceSync(css);
            document.adoptedStyleSheets=document.adoptedStyleSheets.concat([sheet]);
            sheets[key]={sheet:sheet};
            return sheet;
          }
        }catch(e){}
        var el=document.createElement('style');
        el.setAttribute('data-skrrt',key);
        el.textContent=css;
        (document.head||document.documentElement).appendChild(el);
        sheets[key]={el:el};
        return el;
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
