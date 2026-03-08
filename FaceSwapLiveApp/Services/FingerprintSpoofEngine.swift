import Foundation

enum FingerprintSpoofEngine {

    static func spoofScript(for config: FingerprintConfig) -> String {
        let isSafari = config.userAgent.contains("Safari") && !config.userAgent.contains("Chrome")
        let isIOS = config.platform == "iPhone" || config.platform == "iPad"

        var script = "(function(){\n'use strict';\n"
        script += "if(window.__fp_init)return;\n"
        script += "Object.defineProperty(window,'__fp_init',{value:true,enumerable:false,configurable:false,writable:false});\n"
        script += nativeToStringPatch()
        script += navigatorSpoof(config, isSafari: isSafari, isIOS: isIOS)
        script += screenSpoof(config)
        script += timezoneSpoof(config)
        script += canvasNoise(config)
        script += audioNoise(config)
        script += webGLSpoof(config)
        if config.blockWebRTC {
            script += webRTCSpoof()
        }
        if isSafari || isIOS {
            script += safariPluginsAndPDF()
        }
        if config.spoofFonts {
            script += fontSpoof(isIOS: isIOS)
        }
        if isSafari || isIOS {
            script += safariCleanup()
        }
        script += "delete window.__fp_init;\n"
        script += "})();"
        return script
    }

    private static func nativeToStringPatch() -> String {
        var s = ""
        s += "var _nTS=Function.prototype.toString;\n"
        s += "var _reg=new WeakMap();\n"
        s += "function _n(fn,name){\n"
        s += "  _reg.set(fn,name||'');\n"
        s += "  Object.defineProperty(fn,'length',{value:0,configurable:true});\n"
        s += "  if(name)Object.defineProperty(fn,'name',{value:name,configurable:true});\n"
        s += "  return fn;\n"
        s += "}\n"
        s += "var _tsProxy=_n(function toString(){\n"
        s += "  var n=_reg.get(this);\n"
        s += "  if(n!==undefined)return'function '+n+'() {\\n    [native code]\\n}';\n"
        s += "  return _nTS.call(this);\n"
        s += "},'toString');\n"
        s += "_reg.set(_tsProxy,'toString');\n"
        s += "Object.defineProperty(Function.prototype,'toString',{value:_tsProxy,writable:true,configurable:true});\n"
        return s
    }

    private static func navigatorSpoof(_ c: FingerprintConfig, isSafari: Bool, isIOS: Bool) -> String {
        let escapedUA = c.userAgent.replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\\", with: "\\\\")
        let escapedAppVersion = c.userAgent.replacingOccurrences(of: "Mozilla/", with: "").replacingOccurrences(of: "'", with: "\\'")
        let languagesJS = c.languages.map { "'\($0)'" }.joined(separator: ",")
        let primaryLang = c.languages.first ?? "en-US"

        var s = "(function(){\n"
        s += "var N=Navigator.prototype;\n"
        s += "function _dp(o,p,v,g){if(g){Object.defineProperty(o,p,{get:_n(function(){return v},p.replace(/^get /,'')),configurable:true,enumerable:true})}else{Object.defineProperty(o,p,{value:v,writable:false,configurable:true,enumerable:true})}}\n"

        s += "_dp(N,'userAgent','\(escapedUA)',true);\n"
        s += "_dp(N,'appVersion','\(escapedAppVersion)',true);\n"
        s += "_dp(N,'platform','\(c.platform)',true);\n"
        s += "_dp(N,'vendor','\(c.vendor)',true);\n"
        s += "_dp(N,'language','\(primaryLang)',true);\n"
        s += "_dp(N,'languages',Object.freeze([\(languagesJS)]),true);\n"
        s += "_dp(N,'hardwareConcurrency',\(c.hardwareConcurrency),true);\n"
        s += "_dp(N,'deviceMemory',\(c.deviceMemory),true);\n"
        s += "_dp(N,'maxTouchPoints',\(c.maxTouchPoints),true);\n"
        s += "_dp(N,'webdriver',false,true);\n"
        s += "_dp(N,'cookieEnabled',true,true);\n"

        if c.doNotTrack == "unspecified" {
            s += "_dp(N,'doNotTrack',null,true);\n"
        } else {
            s += "_dp(N,'doNotTrack','\(c.doNotTrack)',true);\n"
        }

        if !isSafari {
            let isMobile = c.maxTouchPoints > 0
            let platformOS: String
            if c.platform == "Win32" { platformOS = "Windows" }
            else if c.platform.contains("Linux") { platformOS = "Android" }
            else { platformOS = "macOS" }
            s += "if(N.userAgentData){\n"
            s += "_dp(N,'userAgentData',{brands:[{brand:'Chromium',version:'131'},{brand:'Not_A Brand',version:'24'}],"
            s += "mobile:\(isMobile),platform:'\(platformOS)',"
            s += "getHighEntropyValues:_n(function(hints){return Promise.resolve({architecture:'arm',model:'',platformVersion:'18.3.0',fullVersionList:[{brand:'Chromium',version:'131.0.6778.135'}]})},'getHighEntropyValues'),"
            s += "toJSON:_n(function(){return{brands:this.brands,mobile:this.mobile,platform:this.platform}},'toJSON')"
            s += "},true);}\n"
        }

        s += "})();\n"
        return s
    }

    private static func screenSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){\n"
        s += "var S=Screen.prototype;\n"

        let props: [(String, String)] = [
            ("width", "\(c.screenWidth)"),
            ("height", "\(c.screenHeight)"),
            ("availWidth", "\(c.availWidth)"),
            ("availHeight", "\(c.availHeight)"),
            ("colorDepth", "\(c.colorDepth)"),
            ("pixelDepth", "\(c.colorDepth)")
        ]

        for (prop, val) in props {
            s += "Object.defineProperty(S,'\(prop)',{get:_n(function(){return \(val)},'\(prop)'),configurable:true,enumerable:true});\n"
        }

        s += "Object.defineProperty(window,'devicePixelRatio',{get:_n(function(){return \(c.pixelRatio)},'devicePixelRatio'),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'innerWidth',{get:_n(function(){return \(c.screenWidth)},'innerWidth'),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'innerHeight',{get:_n(function(){return \(c.availHeight)},'innerHeight'),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'outerWidth',{get:_n(function(){return \(c.screenWidth)},'outerWidth'),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'outerHeight',{get:_n(function(){return \(c.screenHeight)},'outerHeight'),configurable:true,enumerable:true});\n"

        s += "})();\n"
        return s
    }

    private static func timezoneSpoof(_ c: FingerprintConfig) -> String {
        let tz = c.timezone.replacingOccurrences(of: "'", with: "\\'")
        let locale = c.languages.first ?? "en-US"
        var s = "(function(){\n"

        s += "var _oDTF=Intl.DateTimeFormat;\n"
        s += "var _cDTF=_n(function DateTimeFormat(loc,opts){\n"
        s += "  opts=Object.assign({},opts||{});\n"
        s += "  if(!opts.timeZone)opts.timeZone='\(tz)';\n"
        s += "  return new _oDTF(loc||'\(locale)',opts);\n"
        s += "},'DateTimeFormat');\n"
        s += "_cDTF.prototype=_oDTF.prototype;\n"
        s += "_cDTF.supportedLocalesOf=_n(_oDTF.supportedLocalesOf.bind(_oDTF),'supportedLocalesOf');\n"
        s += "Object.defineProperty(Intl,'DateTimeFormat',{value:_cDTF,writable:true,configurable:true});\n"

        s += "var _oRO=_oDTF.prototype.resolvedOptions;\n"
        s += "Object.defineProperty(_oDTF.prototype,'resolvedOptions',{value:_n(function resolvedOptions(){\n"
        s += "  var r=_oRO.call(this);\n"
        s += "  if(r.timeZone!=='\(tz)'){\n"
        s += "    try{Object.defineProperty(r,'timeZone',{value:'\(tz)',writable:true,configurable:true})}catch(e){r.timeZone='\(tz)';}\n"
        s += "  }\n"
        s += "  return r;\n"
        s += "},'resolvedOptions'),writable:true,configurable:true});\n"

        s += "Object.defineProperty(Date.prototype,'getTimezoneOffset',{value:_n(function getTimezoneOffset(){return \(c.timezoneOffset);},'getTimezoneOffset'),writable:true,configurable:true});\n"

        s += "var _oTLS=Date.prototype.toLocaleString;\n"
        s += "Object.defineProperty(Date.prototype,'toLocaleString',{value:_n(function toLocaleString(l,o){\n"
        s += "  o=Object.assign({},o||{});if(!o.timeZone)o.timeZone='\(tz)';\n"
        s += "  return _oTLS.call(this,l||'\(locale)',o);\n"
        s += "},'toLocaleString'),writable:true,configurable:true});\n"

        s += "var _oTLTS=Date.prototype.toLocaleTimeString;\n"
        s += "Object.defineProperty(Date.prototype,'toLocaleTimeString',{value:_n(function toLocaleTimeString(l,o){\n"
        s += "  o=Object.assign({},o||{});if(!o.timeZone)o.timeZone='\(tz)';\n"
        s += "  return _oTLTS.call(this,l||'\(locale)',o);\n"
        s += "},'toLocaleTimeString'),writable:true,configurable:true});\n"

        s += "var _oTLDS=Date.prototype.toLocaleDateString;\n"
        s += "Object.defineProperty(Date.prototype,'toLocaleDateString',{value:_n(function toLocaleDateString(l,o){\n"
        s += "  o=Object.assign({},o||{});if(!o.timeZone)o.timeZone='\(tz)';\n"
        s += "  return _oTLDS.call(this,l||'\(locale)',o);\n"
        s += "},'toLocaleDateString'),writable:true,configurable:true});\n"

        s += "})();\n"
        return s
    }

    private static func canvasNoise(_ c: FingerprintConfig) -> String {
        var s = "(function(){\n"
        s += "var _s=\(c.canvasSeed);\n"
        s += "function _m(a){a|=0;a=a+0x6D2B79F5|0;var t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;}\n"
        s += "var _r=_s;\n"
        s += "function _rng(){_r=(_r*16807+1)%2147483647;return _r/2147483647;}\n"

        s += "var _oTDU=HTMLCanvasElement.prototype.toDataURL;\n"
        s += "Object.defineProperty(HTMLCanvasElement.prototype,'toDataURL',{value:_n(function toDataURL(t,q){\n"
        s += "  try{var c=this.getContext('2d');\n"
        s += "  if(c&&this.width>16&&this.height>16){\n"
        s += "    var w=Math.min(this.width,4),h=Math.min(this.height,4);\n"
        s += "    var id=c.getImageData(0,0,w,h);var d=id.data;\n"
        s += "    for(var i=0;i<d.length;i+=4){if(_rng()<0.008){d[i]=(d[i]+(_rng()<0.5?1:-1)+256)%256;}}\n"
        s += "    c.putImageData(id,0,0);\n"
        s += "  }}catch(e){}\n"
        s += "  return _oTDU.call(this,t,q);\n"
        s += "},'toDataURL'),writable:true,configurable:true});\n"

        s += "var _oTB=HTMLCanvasElement.prototype.toBlob;\n"
        s += "Object.defineProperty(HTMLCanvasElement.prototype,'toBlob',{value:_n(function toBlob(cb,t,q){\n"
        s += "  try{var c=this.getContext('2d');\n"
        s += "  if(c&&this.width>16&&this.height>16){\n"
        s += "    var w=Math.min(this.width,4),h=Math.min(this.height,4);\n"
        s += "    var id=c.getImageData(0,0,w,h);var d=id.data;\n"
        s += "    for(var i=0;i<d.length;i+=4){if(_rng()<0.008){d[i]=(d[i]+(_rng()<0.5?1:-1)+256)%256;}}\n"
        s += "    c.putImageData(id,0,0);\n"
        s += "  }}catch(e){}\n"
        s += "  return _oTB.call(this,cb,t,q);\n"
        s += "},'toBlob'),writable:true,configurable:true});\n"

        s += "})();\n"
        return s
    }

    private static func audioNoise(_ c: FingerprintConfig) -> String {
        var s = "(function(){\n"
        s += "var _as=\(c.audioSeed);\n"
        s += "function _arng(){_as=(_as*16807+1)%2147483647;return(_as-1)/2147483646;}\n"

        s += "if(window.AudioBuffer){\n"
        s += "var _oGCD=AudioBuffer.prototype.getChannelData;\n"
        s += "Object.defineProperty(AudioBuffer.prototype,'getChannelData',{value:_n(function getChannelData(ch){\n"
        s += "  var d=_oGCD.call(this,ch);\n"
        s += "  for(var i=0;i<d.length;i+=100){d[i]+=(_arng()-0.5)*0.000005;}\n"
        s += "  return d;\n"
        s += "},'getChannelData'),writable:true,configurable:true});}\n"

        s += "if(window.AudioBuffer&&AudioBuffer.prototype.copyFromChannel){\n"
        s += "var _oCFC=AudioBuffer.prototype.copyFromChannel;\n"
        s += "Object.defineProperty(AudioBuffer.prototype,'copyFromChannel',{value:_n(function copyFromChannel(d,ch,off){\n"
        s += "  _oCFC.call(this,d,ch,off);\n"
        s += "  for(var i=0;i<d.length;i+=100){d[i]+=(_arng()-0.5)*0.000005;}\n"
        s += "},'copyFromChannel'),writable:true,configurable:true});}\n"

        s += "})();\n"
        return s
    }

    private static func webGLSpoof(_ c: FingerprintConfig) -> String {
        let v = c.webGLVendor.replacingOccurrences(of: "'", with: "\\'")
        let r = c.webGLRenderer.replacingOccurrences(of: "'", with: "\\'")
        var s = "(function(){\n"
        s += "function _pGL(P){\n"
        s += "  if(!P)return;\n"
        s += "  var _oGP=P.getParameter;\n"
        s += "  Object.defineProperty(P,'getParameter',{value:_n(function getParameter(p){\n"
        s += "    try{var ext=this.getExtension('WEBGL_debug_renderer_info');\n"
        s += "    if(ext){if(p===ext.UNMASKED_VENDOR_WEBGL)return'\(v)';if(p===ext.UNMASKED_RENDERER_WEBGL)return'\(r)';}\n"
        s += "    }catch(e){}\n"
        s += "    if(p===0x1F00)return'\(v)';if(p===0x1F01)return'\(r)';\n"
        s += "    return _oGP.call(this,p);\n"
        s += "  },'getParameter'),writable:true,configurable:true});\n"
        s += "}\n"
        s += "if(window.WebGLRenderingContext)_pGL(WebGLRenderingContext.prototype);\n"
        s += "if(window.WebGL2RenderingContext)_pGL(WebGL2RenderingContext.prototype);\n"
        s += "})();\n"
        return s
    }

    private static func webRTCSpoof() -> String {
        var s = "(function(){\n"
        s += "if(window.RTCPeerConnection){\n"
        s += "var _oRTC=window.RTCPeerConnection;\n"
        s += "var _nRTC=_n(function RTCPeerConnection(cfg,con){\n"
        s += "  if(cfg&&cfg.iceServers)cfg=Object.assign({},cfg,{iceServers:[]});\n"
        s += "  var pc=new _oRTC(cfg,con);\n"
        s += "  var _oCO=pc.createOffer.bind(pc);\n"
        s += "  pc.createOffer=_n(function createOffer(opts){return _oCO(opts).then(function(offer){\n"
        s += "    if(offer&&offer.sdp){\n"
        s += "      offer.sdp=offer.sdp.replace(/([0-9]{1,3}\\.){3}[0-9]{1,3}/g,'0.0.0.0');\n"
        s += "      offer.sdp=offer.sdp.replace(/[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7}/gi,'::');\n"
        s += "    }return offer;});\n"
        s += "  },'createOffer');\n"
        s += "  return pc;\n"
        s += "},'RTCPeerConnection');\n"
        s += "_nRTC.prototype=_oRTC.prototype;\n"
        s += "Object.defineProperty(window,'RTCPeerConnection',{value:_nRTC,writable:true,configurable:true});\n"
        s += "}\n"
        s += "})();\n"
        return s
    }

    private static func safariPluginsAndPDF() -> String {
        var s = "(function(){\n"
        s += "try{\n"
        s += "var _pNames=['PDF Viewer','Chrome PDF Viewer','Chromium PDF Viewer','Microsoft Edge PDF Viewer','WebKit built-in PDF'];\n"
        s += "var _fps=[];\n"
        s += "for(var i=0;i<_pNames.length;i++){\n"
        s += "  var mt1={type:'application/pdf',suffixes:'pdf',description:'Portable Document Format',enabledPlugin:null};\n"
        s += "  var mt2={type:'text/pdf',suffixes:'pdf',description:'Portable Document Format',enabledPlugin:null};\n"
        s += "  var pl={name:_pNames[i],description:'Portable Document Format',filename:'internal-pdf-viewer',length:2,0:mt1,1:mt2,\n"
        s += "    item:_n(function(j){return this[j]||null},'item'),\n"
        s += "    namedItem:_n(function(n){for(var k=0;k<this.length;k++){if(this[k]&&this[k].type===n)return this[k]}return null},'namedItem')};\n"
        s += "  mt1.enabledPlugin=pl;mt2.enabledPlugin=pl;\n"
        s += "  _fps.push(pl);}\n"
        s += "var _pa={length:_fps.length};\n"
        s += "for(var j=0;j<_fps.length;j++){_pa[j]=_fps[j];_pa[_fps[j].name]=_fps[j];}\n"
        s += "_pa.item=_n(function(i){return this[i]||null},'item');\n"
        s += "_pa.namedItem=_n(function(n){return this[n]||null},'namedItem');\n"
        s += "_pa.refresh=_n(function(){},'refresh');\n"
        s += "Object.defineProperty(Navigator.prototype,'plugins',{get:_n(function(){return _pa},'plugins'),configurable:true,enumerable:true});\n"

        s += "var _mt={length:_fps.length*2};\n"
        s += "var idx=0;for(var i=0;i<_fps.length;i++){_mt[idx++]=_fps[i][0];_mt[idx++]=_fps[i][1];}\n"
        s += "_mt.item=_n(function(i){return this[i]||null},'item');\n"
        s += "_mt.namedItem=_n(function(n){for(var k=0;k<this.length;k++){if(this[k]&&this[k].type===n)return this[k]}return null},'namedItem');\n"
        s += "Object.defineProperty(Navigator.prototype,'mimeTypes',{get:_n(function(){return _mt},'mimeTypes'),configurable:true,enumerable:true});\n"

        s += "Object.defineProperty(Navigator.prototype,'pdfViewerEnabled',{get:_n(function(){return true},'pdfViewerEnabled'),configurable:true,enumerable:true});\n"
        s += "}catch(e){}\n"
        s += "})();\n"
        return s
    }

    private static func fontSpoof(isIOS: Bool) -> String {
        var s = "(function(){\n"
        let iosFonts = "['Gill Sans','Helvetica Neue','Menlo','Academy Engraved LET','Al Nile','American Typewriter','Apple Color Emoji','Apple SD Gothic Neo','Arial','Avenir','Baskerville','Chalkboard SE','Coppersmith','Courier New','Damascus','Futura','Georgia','Heiti SC','Hiragino Sans','Kailasa','Marker Felt','Noteworthy','Optima','Palatino','Savoye LET','Symbol','Thonburi','Times New Roman','Trebuchet MS','Verdana','Zapfino']"
        let defaultFonts = "['Arial','Courier New','Georgia','Helvetica','Times New Roman','Trebuchet MS','Verdana']"
        let fonts = isIOS ? iosFonts : defaultFonts

        s += "var _vF=new Set(\(fonts));\n"
        s += "if(document.fonts&&document.fonts.check){\n"
        s += "var _oCheck=document.fonts.check.bind(document.fonts);\n"
        s += "Object.defineProperty(document.fonts,'check',{value:_n(function check(f,t){\n"
        s += "  try{var parts=(f||'').split(',');\n"
        s += "  for(var i=0;i<parts.length;i++){var fam=parts[i].trim().replace(/[\"']/g,'');if(_vF.has(fam))return true;}\n"
        s += "  return _oCheck(f,t);\n"
        s += "  }catch(e){return false;}\n"
        s += "},'check'),writable:true,configurable:true});}\n"
        s += "})();\n"
        return s
    }

    private static func safariCleanup() -> String {
        var s = "(function(){\n"
        s += "try{delete window.chrome}catch(e){}\n"
        s += "try{Object.defineProperty(window,'chrome',{get:undefined,set:undefined,configurable:true})}catch(e){}\n"
        s += "try{delete window.chrome}catch(e){}\n"
        s += "})();\n"
        return s
    }
}
