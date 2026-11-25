import WebKit

/// Makes pages dark when the app is dark.
///
/// WKWebView has no "force dark" switch. Sites that support `prefers-color-scheme` switch themselves
/// once the web view is set to a dark interface style. For the rest, this script uses the approach
/// described by Dark Reader: look at the page background and, if it is light, invert the whole page
/// and invert images, video and canvas back so photos keep their real colors.
enum SmartDark {
    static var script: WKUserScript {
        WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }

    // swiftlint:disable line_length
    static let source = ##"""
    (function(){
    if(window.__skrrtDark)return;
    window.__skrrtDark=true;
    var mq=window.matchMedia('(prefers-color-scheme: dark)');
    var CSS='html[data-skrrt-dark]{filter:invert(1) hue-rotate(180deg)!important;background:#fff!important}'+
      'html[data-skrrt-dark] img,html[data-skrrt-dark] video,html[data-skrrt-dark] picture,html[data-skrrt-dark] canvas,html[data-skrrt-dark] [style*="background-image"],html[data-skrrt-dark] iframe{filter:invert(1) hue-rotate(180deg)!important}';
    var sheet=null;
    function parse(c){
      var m=c&&c.match(/rgba?\(([^)]+)\)/);
      if(!m)return null;
      var p=m[1].split(',').map(function(x){return parseFloat(x);});
      if(p.length>3&&p[3]<0.1)return null;
      return p;
    }
    function lum(p){return(0.299*p[0]+0.587*p[1]+0.114*p[2])/255;}
    function pageColor(){
      var b=document.body,h=document.documentElement;
      var p=b&&parse(getComputedStyle(b).backgroundColor);
      if(!p)p=parse(getComputedStyle(h).backgroundColor);
      return p;
    }
    function on(){
      var root=document.documentElement;
      if(root.hasAttribute('data-skrrt-dark'))return;
      root.setAttribute('data-skrrt-dark','1');
      try{
        if(!sheet){sheet=new CSSStyleSheet();sheet.replaceSync(CSS);}
        document.adoptedStyleSheets=document.adoptedStyleSheets.concat([sheet]);
      }catch(e){
        var s=document.createElement('style');
        s.id='skrrt-dark-css';
        s.textContent=CSS;
        root.appendChild(s);
      }
    }
    function off(){
      document.documentElement.removeAttribute('data-skrrt-dark');
      if(sheet)document.adoptedStyleSheets=document.adoptedStyleSheets.filter(function(s){return s!==sheet;});
      var e=document.getElementById('skrrt-dark-css');
      if(e)e.remove();
    }
    function check(){
      if(!mq.matches){off();return;}
      var p=pageColor();
      var light=p?lum(p)>0.6:true;
      if(light)on();else off();
    }
    check();
    window.addEventListener('load',function(){setTimeout(check,300);});
    setTimeout(check,1500);
    setTimeout(check,4000);
    if(mq.addEventListener)mq.addEventListener('change',check);
    })();
    """##
}
