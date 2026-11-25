import Foundation

/// Plugins that ship with Skrrt. Names and summaries are catalog keys that the UI localizes.
enum BuiltInPlugins {
    static let all: [Plugin] = [
        // MARK: Look
        style(
            "builtin.dark", "Force Dark Mode", "Inverts light pages that have no dark theme", "moon.fill", .appearance,
            ##"html{filter:invert(1) hue-rotate(180deg)!important;background:#fff!important}img,video,picture,canvas,svg,iframe,[style*="background-image"]{filter:invert(1) hue-rotate(180deg)!important}"##
        ),
        style(
            "builtin.night", "Night Shift", "Warm, eye-friendly tint over every page", "sun.haze.fill", .appearance,
            ##"html::after{content:"";position:fixed;inset:0;background:rgba(255,140,0,.13);pointer-events:none;z-index:2147483647;mix-blend-mode:multiply}"##
        ),
        style(
            "builtin.gray", "Grayscale", "Shows every page in black and white", "circle.lefthalf.filled", .appearance,
            ##"html{filter:grayscale(1)!important}"##
        ),
        style(
            "builtin.motion", "Reduce Motion", "Turns off animations and smooth scrolling", "wind", .appearance,
            ##"*,*::before,*::after{animation-duration:.001s!important;animation-iteration-count:1!important;transition-duration:.001s!important;scroll-behavior:auto!important}"##
        ),
        script(
            "builtin.branding", "Clean Search Pages", "Hides the search engine logo on result pages", "magnifyingglass", .appearance, on: true,
            ##"""
            if(!/(^|\.)(google|bing|duckduckgo|yandex|startpage|ecosia)\./.test(location.hostname)&&location.hostname!=='search.brave.com')return;
            Skrrt.addStyle('#logo,#logocont,#hplogo,a[aria-label="Google"],a[title="Google"],header a[href*="duckduckgo.com"] img{display:none!important}');
            """##
        ),

        // MARK: Privacy
        style(
            "builtin.cookies", "Hide Cookie Banners", "Hides common consent pop-ups", "shield.lefthalf.filled", .privacy, on: true,
            ##"#onetrust-banner-sdk,#onetrust-consent-sdk,#CybotCookiebotDialog,.cc-window,.cookie-banner,.cookie-notice,.cookie-consent,#cookie-banner,#cookieBanner,[id^="sp_message_container"],[class*="cookie-banner"],[class*="CookieBanner"],[aria-label*="cookie" i]{display:none!important}"##
        ),
        script(
            "builtin.overlays", "Remove Pop-up Overlays", "Removes full-screen subscribe and newsletter walls", "xmark.rectangle", .privacy,
            ##"""
            function unlock(){[document.documentElement,document.body].forEach(function(e){if(e)e.style.setProperty('overflow','auto','important');});}
            function sweep(){
              var vw=innerWidth,vh=innerHeight,hit=false;
              document.querySelectorAll('body *').forEach(function(n){
                var cs=getComputedStyle(n);
                if((cs.position==='fixed'||cs.position==='sticky')&&parseInt(cs.zIndex||'0',10)>=100){
                  var r=n.getBoundingClientRect();
                  if(r.width>=vw*0.6&&r.height>=vh*0.5&&!/cookie|consent/i.test(n.className+n.id)){n.remove();hit=true;}
                }
              });
              if(hit)unlock();
            }
            var runs=0,id=Skrrt.every(1200,function(){sweep();if(++runs>8)clearInterval(id);});
            """##
        ),
        script(
            "builtin.links", "Clean Links", "Removes tracking pings and search engine redirects", "link", .privacy,
            ##"""
            Skrrt.observe('a[href]',function(a){
              a.removeAttribute('ping');
              try{
                var u=new URL(a.href,location.href);
                if(/(^|\.)google\.[a-z.]+$/.test(u.hostname)&&u.pathname==='/url'){
                  var t=u.searchParams.get('q')||u.searchParams.get('url');
                  if(t)a.href=t;
                }
              }catch(e){}
            });
            """##
        ),

        // MARK: Video
        script(
            "builtin.youtube", "YouTube Ad Skipper", "Hides ad slots and skips video ads on YouTube", "play.rectangle.fill", .video,
            matches: ["youtube.com"],
            ##"""
            Skrrt.addStyle('.ytp-ad-overlay-container,.ytp-ad-module,#player-ads,ytd-display-ad-renderer,ytd-promoted-sparkles-web-renderer,ytd-ad-slot-renderer,ytd-banner-promo-renderer,#masthead-ad{display:none!important}');
            var mutedByUs=false;
            Skrrt.every(400,function(){
              var player=document.querySelector('.html5-video-player');
              var video=document.querySelector('video.html5-main-video');
              if(!player||!video)return;
              if(player.classList.contains('ad-showing')){
                if(!video.muted){video.muted=true;mutedByUs=true;}
                if(isFinite(video.duration)&&video.duration>0)video.currentTime=video.duration;
                var skip=document.querySelector('.ytp-ad-skip-button,.ytp-ad-skip-button-modern,.ytp-skip-ad-button');
                if(skip)skip.click();
              }else if(mutedByUs){video.muted=false;mutedByUs=false;}
            });
            """##
        ),
        script(
            "builtin.speed", "Video Speed Control", "A floating button that changes playback speed", "speedometer", .video,
            ##"""
            var speeds=[1,1.25,1.5,1.75,2,0.75],i=Skrrt.storage.get('i',0);
            var btn=Skrrt.el('button',{style:{position:'fixed',left:'12px',bottom:'96px',zIndex:2147483647,padding:'8px 12px',font:'600 14px -apple-system,sans-serif',color:'#fff',background:'rgba(20,20,24,.72)',border:'1px solid rgba(255,255,255,.25)',borderRadius:'999px',display:'none'}});
            function apply(){var rate=speeds[i];btn.textContent=rate+'×';document.querySelectorAll('video').forEach(function(v){v.playbackRate=rate;});}
            btn.addEventListener('click',function(){i=(i+1)%speeds.length;Skrrt.storage.set('i',i);apply();});
            Skrrt.ready(function(){document.body.appendChild(btn);});
            Skrrt.every(800,function(){var has=document.querySelector('video');btn.style.display=has?'block':'none';if(has)apply();});
            """##
        ),
        script(
            "builtin.autoplay", "Block Video Autoplay", "Stops videos that start playing on their own", "pause.rectangle", .video, atStart: true,
            ##"""
            var last=0;
            ['touchstart','click','keydown'].forEach(function(t){addEventListener(t,function(){last=Date.now();},true);});
            document.addEventListener('play',function(e){
              var v=e.target;
              if(v&&v.tagName==='VIDEO'&&Date.now()-last>1500)v.pause();
            },true);
            """##
        ),

        // MARK: Reading
        style(
            "builtin.reader", "Reading Mode", "A calm, narrow layout with serif text", "book.fill", .reading,
            ##"html{font-size:19px!important}body{max-width:720px!important;margin:0 auto!important;padding:16px!important;line-height:1.65!important;font-family:Georgia,'Times New Roman',serif!important;background:#fbf7ee!important;color:#222!important}aside,nav,footer,header,[class*="sidebar"],[class*="banner"],[class*="advert"],[id*="advert"],[class*="promo"],[class*="newsletter"]{display:none!important}img{max-width:100%!important;height:auto!important}"##
        ),
        style(
            "builtin.bigtext", "Bigger Text", "Makes text 25 percent larger on every site", "textformat.size", .reading,
            ##"html{-webkit-text-size-adjust:125%!important;text-size-adjust:125%!important}"##
        ),
        style(
            "builtin.textonly", "Text Only", "Hides images and video to save data", "text.alignleft", .reading,
            ##"img,picture,video,iframe{display:none!important}"##
        ),

        // MARK: Tools
        script(
            "builtin.select", "Allow Copy and Selection", "Unlocks text selection and the context menu", "doc.on.clipboard", .tools,
            ##"""
            Skrrt.addStyle('*{-webkit-user-select:text!important;user-select:text!important;-webkit-touch-callout:default!important}');
            ['copy','cut','contextmenu','selectstart','dragstart'].forEach(function(t){
              document.addEventListener(t,function(e){e.stopImmediatePropagation();},true);
            });
            """##
        ),
        script(
            "builtin.sametab", "Open Links in Same Tab", "Stops links from opening new windows", "arrow.up.right.square", .tools,
            ##"""
            document.addEventListener('click',function(e){
              var a=e.target.closest&&e.target.closest('a[target]');
              if(a&&a.target==='_blank')a.removeAttribute('target');
            },true);
            Skrrt.observe('a[target="_blank"]',function(a){a.removeAttribute('target');});
            """##
        ),
        script(
            "builtin.unstick", "Unstick Headers", "Turns fixed top bars into normal page content", "pin.slash", .tools,
            ##"""
            function sweep(){
              document.querySelectorAll('body *').forEach(function(n){
                var cs=getComputedStyle(n);
                if((cs.position==='fixed'||cs.position==='sticky')&&n.getBoundingClientRect().top<120&&n.offsetHeight<220){
                  n.style.setProperty('position','static','important');
                }
              });
            }
            Skrrt.ready(function(){sweep();var runs=0,id=Skrrt.every(1500,function(){sweep();if(++runs>6)clearInterval(id);});});
            """##
        ),
        script(
            "builtin.top", "Back to Top Button", "A round button that scrolls to the top", "arrow.up.circle.fill", .tools,
            ##"""
            var b=Skrrt.el('button',{'aria-label':'Top',text:'↑',style:{position:'fixed',right:'14px',bottom:'96px',width:'44px',height:'44px',borderRadius:'22px',zIndex:2147483647,font:'700 20px -apple-system,sans-serif',color:'#fff',background:'rgba(20,20,24,.72)',border:'1px solid rgba(255,255,255,.25)',display:'none'}});
            b.addEventListener('click',function(){scrollTo({top:0,behavior:'smooth'});});
            Skrrt.ready(function(){document.body.appendChild(b);});
            addEventListener('scroll',function(){b.style.display=scrollY>600?'block':'none';},{passive:true});
            """##
        )
    ]

    private static func style(
        _ id: String, _ name: String, _ summary: String, _ icon: String, _ category: PluginCategory,
        on: Bool = false, _ css: String
    ) -> Plugin {
        Plugin(
            id: id, name: name, summary: summary, icon: icon, category: category, kind: .style,
            matches: [], excludes: [], runsAtStart: false, version: "1.0", code: css, isEnabled: on, isBuiltIn: true
        )
    }

    private static func script(
        _ id: String, _ name: String, _ summary: String, _ icon: String, _ category: PluginCategory,
        on: Bool = false, matches: [String] = [], atStart: Bool = false, _ code: String
    ) -> Plugin {
        Plugin(
            id: id, name: name, summary: summary, icon: icon, category: category, kind: .script,
            matches: matches, excludes: [], runsAtStart: atStart, version: "1.0", code: code, isEnabled: on, isBuiltIn: true
        )
    }
}
