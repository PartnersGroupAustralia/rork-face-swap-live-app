import Foundation

enum FingerprintSpoofEngine {
    static func spoofScript(for config: FingerprintConfig) -> String {
        let languagesArrayJS = config.languages.map { "'\($0)'" }.joined(separator: ",")

        var script = "(function(){\n'use strict';\nif(window.__adSpoofed)return;\nwindow.__adSpoofed=true;\n"
        script += "var _dp=Object.defineProperty;\n"
        script += "function safeDefine(obj,prop,val){try{_dp(obj,prop,{get:function(){return val;},configurable:true,enumerable:true});}catch(e){}}\n"
        script += navigatorSpoof(config, languagesArrayJS: languagesArrayJS)
        script += screenSpoof(config)
        script += timezoneSpoof(config)
        script += canvasSpoof(config)
        script += webGLSpoof(config)
        script += audioSpoof(config)
        script += webRTCSpoof(config)
        script += pluginsSpoof()
        script += fontSpoof(config)
        script += automationSpoof()
        script += permissionsSpoof()
        script += "})();"
        return script
    }

    private static func navigatorSpoof(_ c: FingerprintConfig, languagesArrayJS: String) -> String {
        let escapedUA = c.userAgent.replacingOccurrences(of: "'", with: "\\'")
        let escapedAppVersion = c.userAgent.replacingOccurrences(of: "Mozilla/", with: "").replacingOccurrences(of: "'", with: "\\'")
        let isMobile = c.maxTouchPoints > 0
        let platformOS: String
        if c.platform.contains("iPhone") || c.platform.contains("iPad") {
            platformOS = "iOS"
        } else if c.platform == "Win32" {
            platformOS = "Windows"
        } else if c.platform.contains("Linux") {
            platformOS = "Android"
        } else {
            platformOS = "macOS"
        }

        var s = "(function(){"
        s += "var navProps={"
        s += "userAgent:'\(escapedUA)',"
        s += "platform:'\(c.platform)',"
        s += "vendor:'\(c.vendor)',"
        s += "language:'\(c.languages.first ?? "en-US")',"
        s += "hardwareConcurrency:\(c.hardwareConcurrency),"
        s += "maxTouchPoints:\(c.maxTouchPoints),"
        s += "appVersion:'\(escapedAppVersion)'"
        s += "};"
        s += "for(var k in navProps){safeDefine(Navigator.prototype,k,navProps[k]);}"
        s += "try{_dp(Navigator.prototype,'languages',{get:function(){return Object.freeze([\(languagesArrayJS)]);},configurable:true,enumerable:true});}catch(e){}"
        s += "try{_dp(Navigator.prototype,'deviceMemory',{get:function(){return \(c.deviceMemory);},configurable:true,enumerable:true});}catch(e){}"
        s += "var dnt='\(c.doNotTrack)';"
        s += "if(dnt==='unspecified'){safeDefine(Navigator.prototype,'doNotTrack',null);}else{safeDefine(Navigator.prototype,'doNotTrack',dnt);}"
        s += "if(Navigator.prototype.userAgentData){"
        s += "try{_dp(Navigator.prototype,'userAgentData',{get:function(){"
        s += "return{brands:[{brand:'Not_A Brand',version:'8'},{brand:'Chromium',version:'131'}],"
        s += "mobile:\(isMobile),platform:'\(platformOS)',"
        s += "getHighEntropyValues:function(){return Promise.resolve({architecture:'arm',model:'',platformVersion:'18.3.0',fullVersionList:[{brand:'Chromium',version:'131.0.6778.135'}]});}"
        s += "};},configurable:true});}catch(e){}}"
        s += "})();"
        return s
    }

    private static func screenSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){"
        s += "safeDefine(Screen.prototype,'width',\(c.screenWidth));"
        s += "safeDefine(Screen.prototype,'height',\(c.screenHeight));"
        s += "safeDefine(Screen.prototype,'availWidth',\(c.availWidth));"
        s += "safeDefine(Screen.prototype,'availHeight',\(c.availHeight));"
        s += "safeDefine(Screen.prototype,'colorDepth',\(c.colorDepth));"
        s += "safeDefine(Screen.prototype,'pixelDepth',\(c.colorDepth));"
        s += "safeDefine(window,'devicePixelRatio',\(c.pixelRatio));"
        s += "safeDefine(window,'innerWidth',\(c.screenWidth));"
        s += "safeDefine(window,'innerHeight',\(c.screenHeight));"
        s += "safeDefine(window,'outerWidth',\(c.screenWidth));"
        s += "safeDefine(window,'outerHeight',\(c.screenHeight));"
        s += "})();"
        return s
    }

    private static func timezoneSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){"
        s += "var tz='\(c.timezone)';var off=\(c.timezoneOffset);"
        s += "var origDTF=Intl.DateTimeFormat;"
        s += "var newDTF=function(loc,opts){opts=Object.assign({},opts||{});if(!opts.timeZone)opts.timeZone=tz;return new origDTF(loc,opts);};"
        s += "newDTF.prototype=origDTF.prototype;newDTF.supportedLocalesOf=origDTF.supportedLocalesOf;"
        s += "try{Intl.DateTimeFormat=newDTF;}catch(e){}"
        s += "try{var origResolve=origDTF.prototype.resolvedOptions;origDTF.prototype.resolvedOptions=function(){var r=origResolve.call(this);r.timeZone=tz;return r;};}catch(e){}"
        s += "Date.prototype.getTimezoneOffset=function(){return off;};"
        s += "Date.prototype.getTimezoneOffset.toString=function(){return'function getTimezoneOffset() { [native code] }';};"
        s += "})();"
        return s
    }

    private static func canvasSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){"
        s += "var seed=\(c.canvasSeed);"
        s += "function m32(a){return function(){a|=0;a=a+0x6D2B79F5|0;var t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}"
        s += "var rng=m32(seed);"
        s += "var origTDU=HTMLCanvasElement.prototype.toDataURL;"
        s += "HTMLCanvasElement.prototype.toDataURL=function(t,q){"
        s += "try{var ctx=this.getContext('2d');if(ctx&&this.width>0&&this.height>0){var w=Math.min(this.width,64),h=Math.min(this.height,64);var id=ctx.getImageData(0,0,w,h);var d=id.data;for(var i=0;i<d.length;i+=4){if(rng()<0.01){d[i]^=(rng()*2|0);d[i+1]^=(rng()*2|0);}}ctx.putImageData(id,0,0);}}catch(e){}"
        s += "return origTDU.call(this,t,q);};"
        s += "HTMLCanvasElement.prototype.toDataURL.toString=function(){return'function toDataURL() { [native code] }';};"
        s += "var origTB=HTMLCanvasElement.prototype.toBlob;"
        s += "HTMLCanvasElement.prototype.toBlob=function(cb,t,q){"
        s += "try{var ctx=this.getContext('2d');if(ctx&&this.width>0&&this.height>0){var w=Math.min(this.width,64),h=Math.min(this.height,64);var id=ctx.getImageData(0,0,w,h);var d=id.data;for(var i=0;i<d.length;i+=4){if(rng()<0.01){d[i]^=(rng()*2|0);d[i+1]^=(rng()*2|0);}}ctx.putImageData(id,0,0);}}catch(e){}"
        s += "return origTB.call(this,cb,t,q);};"
        s += "HTMLCanvasElement.prototype.toBlob.toString=function(){return'function toBlob() { [native code] }';};"
        s += "})();"
        return s
    }

    private static func webGLSpoof(_ c: FingerprintConfig) -> String {
        let escapedVendor = c.webGLVendor.replacingOccurrences(of: "'", with: "\\'")
        let escapedRenderer = c.webGLRenderer.replacingOccurrences(of: "'", with: "\\'")
        var s = "(function(){"
        s += "var vend='\(escapedVendor)';var rend='\(escapedRenderer)';"
        s += "function patchGL(Proto){if(!Proto)return;"
        s += "var origGP=Proto.getParameter;"
        s += "Proto.getParameter=function(p){"
        s += "var ext=null;try{ext=this.getExtension('WEBGL_debug_renderer_info');}catch(e){}"
        s += "if(ext){if(p===ext.UNMASKED_VENDOR_WEBGL)return vend;if(p===ext.UNMASKED_RENDERER_WEBGL)return rend;}"
        s += "if(p===0x1F00)return vend;if(p===0x1F01)return rend;"
        s += "return origGP.call(this,p);};"
        s += "Proto.getParameter.toString=function(){return'function getParameter() { [native code] }';};}"
        s += "if(window.WebGLRenderingContext)patchGL(WebGLRenderingContext.prototype);"
        s += "if(window.WebGL2RenderingContext)patchGL(WebGL2RenderingContext.prototype);"
        s += "})();"
        return s
    }

    private static func audioSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){"
        s += "var seed=\(c.audioSeed);var st=seed;"
        s += "function prng(){st=(st*16807)%2147483647;return(st-1)/2147483646;}"
        s += "if(window.AudioBuffer){"
        s += "var origGCD=AudioBuffer.prototype.getChannelData;"
        s += "AudioBuffer.prototype.getChannelData=function(ch){var d=origGCD.call(this,ch);for(var i=0;i<d.length;i+=100){d[i]+=(prng()-0.5)*0.0001;}return d;};"
        s += "AudioBuffer.prototype.getChannelData.toString=function(){return'function getChannelData() { [native code] }';};}"
        s += "if(window.AudioBuffer&&AudioBuffer.prototype.copyFromChannel){"
        s += "var origCFC=AudioBuffer.prototype.copyFromChannel;"
        s += "AudioBuffer.prototype.copyFromChannel=function(dest,ch,off){origCFC.call(this,dest,ch,off);for(var i=0;i<dest.length;i+=100){dest[i]+=(prng()-0.5)*0.0001;}};"
        s += "AudioBuffer.prototype.copyFromChannel.toString=function(){return'function copyFromChannel() { [native code] }';};}"
        s += "})();"
        return s
    }

    private static func webRTCSpoof(_ c: FingerprintConfig) -> String {
        guard c.blockWebRTC else { return "" }
        var s = "(function(){"
        s += "if(window.RTCPeerConnection){"
        s += "var origRTC=window.RTCPeerConnection;"
        s += "window.RTCPeerConnection=function(cfg,con){"
        s += "if(cfg&&cfg.iceServers)cfg.iceServers=[];"
        s += "var pc=new origRTC(cfg,con);"
        s += "var origCO=pc.createOffer.bind(pc);"
        s += "pc.createOffer=function(opts){return origCO(opts).then(function(offer){"
        s += "if(offer&&offer.sdp){"
        s += "offer.sdp=offer.sdp.replace(/([0-9]{1,3}[.]){3}[0-9]{1,3}/g,'0.0.0.0');"
        s += "offer.sdp=offer.sdp.replace(/[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7}/gi,'::');"
        s += "}return offer;});};"
        s += "return pc;};"
        s += "window.RTCPeerConnection.prototype=origRTC.prototype;"
        s += "window.RTCPeerConnection.toString=function(){return'function RTCPeerConnection() { [native code] }';};}"
        s += "})();"
        return s
    }

    private static func pluginsSpoof() -> String {
        var s = "(function(){"
        s += "safeDefine(Navigator.prototype,'plugins',[]);"
        s += "safeDefine(Navigator.prototype,'mimeTypes',[]);"
        s += "try{_dp(Navigator.prototype,'pdfViewerEnabled',{get:function(){return false;},configurable:true});}catch(e){}"
        s += "})();"
        return s
    }

    private static func fontSpoof(_ c: FingerprintConfig) -> String {
        guard c.spoofFonts else { return "" }
        var s = "(function(){"
        s += "var baseFonts=['Arial','Courier New','Georgia','Times New Roman','Verdana','Helvetica','Trebuchet MS'];"
        s += "if(document.fonts&&document.fonts.check){"
        s += "var origCheck=document.fonts.check.bind(document.fonts);"
        s += "document.fonts.check=function(f,t){"
        s += "var fam=(f||'').toLowerCase();"
        s += "var isBase=baseFonts.some(function(b){return fam.indexOf(b.toLowerCase())>=0;});"
        s += "if(isBase)return true;return false;};"
        s += "document.fonts.check.toString=function(){return'function check() { [native code] }';};}"
        s += "})();"
        return s
    }

    private static func automationSpoof() -> String {
        var s = "(function(){"
        s += "safeDefine(Navigator.prototype,'webdriver',false);"
        s += "try{delete Navigator.prototype.webdriver;}catch(e){}"
        s += "try{if(window.chrome===void 0){window.chrome={runtime:{},csi:function(){return{};}};};}catch(e){}"
        s += "})();"
        return s
    }

    private static func permissionsSpoof() -> String {
        var s = "(function(){"
        s += "if(navigator.permissions&&navigator.permissions.query){"
        s += "var origQuery=navigator.permissions.query.bind(navigator.permissions);"
        s += "navigator.permissions.query=function(desc){"
        s += "if(desc&&desc.name==='notifications'){return Promise.resolve({state:'prompt',onchange:null});}"
        s += "return origQuery(desc);};"
        s += "navigator.permissions.query.toString=function(){return'function query() { [native code] }';};}"
        s += "})();"
        return s
    }
}
