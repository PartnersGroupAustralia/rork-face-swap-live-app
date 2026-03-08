import Foundation

enum FingerprintSpoofEngine {
    static func spoofScript(for config: FingerprintConfig) -> String {
        let isSafari = config.userAgent.contains("Safari") && !config.userAgent.contains("Chrome")
        let isIOS = config.platform == "iPhone" || config.platform == "iPad"

        var script = "(function(){\n'use strict';\nif(window.__fp_init)return;\nwindow.__fp_init=true;\n"
        script += patchToString()
        script += navigatorSpoof(config, isSafari: isSafari, isIOS: isIOS)
        script += screenSpoof(config)
        script += timezoneSpoof(config)
        script += canvasSpoof(config)
        script += webGLSpoof(config)
        script += audioSpoof(config)
        script += webRTCSpoof(config)
        script += batterySpoof(isSafari: isSafari)
        script += storageSpoof()
        if config.spoofFonts {
            script += fontSpoof(config, isIOS: isIOS)
        }
        script += cleanupSpoof(isSafari: isSafari)
        script += "})();"
        return script
    }

    private static func patchToString() -> String {
        var s = ""
        s += "var _origToStr=Function.prototype.toString;\n"
        s += "var _patchedFns=new WeakSet();\n"
        s += "var _fnNames=new WeakMap();\n"
        s += "function _markNative(fn,name){"
        s += "_patchedFns.add(fn);"
        s += "_fnNames.set(fn,name||'');"
        s += "return fn;}\n"
        s += "Function.prototype.toString=_markNative(function toString(){"
        s += "if(_patchedFns.has(this)){"
        s += "var n=_fnNames.get(this)||this.name||'';"
        s += "return'function '+n+'() { [native code] }';}"
        s += "return _origToStr.call(this);},'toString');\n"
        return s
    }

    private static func navigatorSpoof(_ c: FingerprintConfig, isSafari: Bool, isIOS: Bool) -> String {
        let escapedUA = c.userAgent.replacingOccurrences(of: "'", with: "\\'")
        let escapedAppVersion = c.userAgent.replacingOccurrences(of: "Mozilla/", with: "").replacingOccurrences(of: "'", with: "\\'")
        let languagesJS = c.languages.map { "'\($0)'" }.joined(separator: ",")

        var s = "(function(){\n"
        s += "var N=Navigator.prototype;\n"

        s += "var _origUA=Object.getOwnPropertyDescriptor(N,'userAgent');\n"
        s += "if(_origUA&&_origUA.get){"
        s += "Object.defineProperty(N,'userAgent',{get:_markNative(function userAgent(){return '\(escapedUA)';},'get userAgent'),configurable:true,enumerable:true});"
        s += "}else{try{Object.defineProperty(N,'userAgent',{value:'\(escapedUA)',writable:false,configurable:true,enumerable:true});}catch(e){}}\n"

        s += "var _origPlat=Object.getOwnPropertyDescriptor(N,'platform');\n"
        s += "if(_origPlat&&_origPlat.get){"
        s += "Object.defineProperty(N,'platform',{get:_markNative(function platform(){return '\(c.platform)';},'get platform'),configurable:true,enumerable:true});"
        s += "}else{try{Object.defineProperty(N,'platform',{value:'\(c.platform)',writable:false,configurable:true,enumerable:true});}catch(e){}}\n"

        s += "Object.defineProperty(N,'vendor',{get:_markNative(function vendor(){return '\(c.vendor)';},'get vendor'),configurable:true,enumerable:true});\n"

        s += "Object.defineProperty(N,'language',{get:_markNative(function language(){return '\(c.languages.first ?? "en-US")';},'get language'),configurable:true,enumerable:true});\n"

        s += "Object.defineProperty(N,'languages',{get:_markNative(function languages(){return Object.freeze([\(languagesJS)]);},'get languages'),configurable:true,enumerable:true});\n"

        s += "Object.defineProperty(N,'hardwareConcurrency',{get:_markNative(function hardwareConcurrency(){return \(c.hardwareConcurrency);},'get hardwareConcurrency'),configurable:true,enumerable:true});\n"

        s += "Object.defineProperty(N,'maxTouchPoints',{get:_markNative(function maxTouchPoints(){return \(c.maxTouchPoints);},'get maxTouchPoints'),configurable:true,enumerable:true});\n"

        s += "Object.defineProperty(N,'deviceMemory',{get:_markNative(function deviceMemory(){return \(c.deviceMemory);},'get deviceMemory'),configurable:true,enumerable:true});\n"

        s += "Object.defineProperty(N,'appVersion',{get:_markNative(function appVersion(){return '\(escapedAppVersion)';},'get appVersion'),configurable:true,enumerable:true});\n"

        s += "var dnt='\(c.doNotTrack)';\n"
        s += "if(dnt==='unspecified'){"
        s += "Object.defineProperty(N,'doNotTrack',{get:_markNative(function doNotTrack(){return null;},'get doNotTrack'),configurable:true,enumerable:true});"
        s += "}else{"
        s += "Object.defineProperty(N,'doNotTrack',{get:_markNative(function doNotTrack(){return dnt;},'get doNotTrack'),configurable:true,enumerable:true});"
        s += "}\n"

        s += "Object.defineProperty(N,'webdriver',{get:_markNative(function webdriver(){return false;},'get webdriver'),configurable:true,enumerable:true});\n"

        if !isSafari {
            let isMobile = c.maxTouchPoints > 0
            let platformOS: String
            if c.platform == "Win32" {
                platformOS = "Windows"
            } else if c.platform.contains("Linux") {
                platformOS = "Android"
            } else {
                platformOS = "macOS"
            }
            s += "if(N.userAgentData){"
            s += "Object.defineProperty(N,'userAgentData',{get:_markNative(function userAgentData(){"
            s += "return{brands:[{brand:'Chromium',version:'131'},{brand:'Not_A Brand',version:'24'}],"
            s += "mobile:\(isMobile),platform:'\(platformOS)',"
            s += "getHighEntropyValues:_markNative(function getHighEntropyValues(){return Promise.resolve({architecture:'arm',model:'',platformVersion:'18.3.0',fullVersionList:[{brand:'Chromium',version:'131.0.6778.135'}]});},'getHighEntropyValues')"
            s += "};},'get userAgentData'),configurable:true});}\n"
        }

        s += "})();\n"
        return s
    }

    private static func screenSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){\n"
        s += "var S=Screen.prototype;\n"

        let screenProps: [(String, String)] = [
            ("width", "\(c.screenWidth)"),
            ("height", "\(c.screenHeight)"),
            ("availWidth", "\(c.availWidth)"),
            ("availHeight", "\(c.availHeight)"),
            ("colorDepth", "\(c.colorDepth)"),
            ("pixelDepth", "\(c.colorDepth)")
        ]

        for (prop, val) in screenProps {
            s += "Object.defineProperty(S,'\(prop)',{get:_markNative(function \(prop)(){return \(val);},'get \(prop)'),configurable:true,enumerable:true});\n"
        }

        s += "Object.defineProperty(window,'devicePixelRatio',{get:_markNative(function devicePixelRatio(){return \(c.pixelRatio);},'get devicePixelRatio'),configurable:true,enumerable:true});\n"

        let sf = c.screenFrame
        s += "Object.defineProperty(window,'screenX',{get:_markNative(function screenX(){return \(sf.x);},'get screenX'),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'screenY',{get:_markNative(function screenY(){return \(sf.y);},'get screenY'),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'outerWidth',{get:_markNative(function outerWidth(){return \(c.screenWidth);},'get outerWidth'),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'outerHeight',{get:_markNative(function outerHeight(){return \(c.screenHeight);},'get outerHeight'),configurable:true,enumerable:true});\n"

        s += "})();\n"
        return s
    }

    private static func timezoneSpoof(_ c: FingerprintConfig) -> String {
        let escapedTZ = c.timezone.replacingOccurrences(of: "'", with: "\\'")
        var s = "(function(){\n"
        s += "var _tz='\(escapedTZ)';var _off=\(c.timezoneOffset);\n"

        s += "var _origDTF=Intl.DateTimeFormat;\n"
        s += "var _DTFProxy=_markNative(function DateTimeFormat(loc,opts){"
        s += "opts=Object.assign({},opts||{});"
        s += "if(!opts.timeZone)opts.timeZone=_tz;"
        s += "return new _origDTF(loc,opts);"
        s += "},'DateTimeFormat');\n"

        s += "_DTFProxy.prototype=_origDTF.prototype;\n"
        s += "_DTFProxy.supportedLocalesOf=_origDTF.supportedLocalesOf;\n"
        s += "Intl.DateTimeFormat=_DTFProxy;\n"

        s += "var _origRO=_origDTF.prototype.resolvedOptions;\n"
        s += "_origDTF.prototype.resolvedOptions=_markNative(function resolvedOptions(){"
        s += "var r=_origRO.call(this);"
        s += "try{Object.defineProperty(r,'timeZone',{value:_tz,writable:true,configurable:true});}catch(e){r.timeZone=_tz;}"
        s += "return r;"
        s += "},'resolvedOptions');\n"

        s += "Date.prototype.getTimezoneOffset=_markNative(function getTimezoneOffset(){return _off;},'getTimezoneOffset');\n"

        let locale = c.languages.first ?? "en-US"
        s += "var _origTLS=Date.prototype.toLocaleString;\n"
        s += "Date.prototype.toLocaleString=_markNative(function toLocaleString(l,o){"
        s += "o=Object.assign({},o||{});"
        s += "if(!o.timeZone)o.timeZone=_tz;"
        s += "return _origTLS.call(this,l||'\(locale)',o);"
        s += "},'toLocaleString');\n"

        s += "var _origTLTS=Date.prototype.toLocaleTimeString;\n"
        s += "Date.prototype.toLocaleTimeString=_markNative(function toLocaleTimeString(l,o){"
        s += "o=Object.assign({},o||{});"
        s += "if(!o.timeZone)o.timeZone=_tz;"
        s += "return _origTLTS.call(this,l||'\(locale)',o);"
        s += "},'toLocaleTimeString');\n"

        s += "var _origTLDS=Date.prototype.toLocaleDateString;\n"
        s += "Date.prototype.toLocaleDateString=_markNative(function toLocaleDateString(l,o){"
        s += "o=Object.assign({},o||{});"
        s += "if(!o.timeZone)o.timeZone=_tz;"
        s += "return _origTLDS.call(this,l||'\(locale)',o);"
        s += "},'toLocaleDateString');\n"

        s += "})();\n"
        return s
    }

    private static func canvasSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){\n"
        s += "var _seed=\(c.canvasSeed);\n"
        s += "function _m32(a){return function(){a|=0;a=a+0x6D2B79F5|0;var t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}\n"
        s += "var _rng=_m32(_seed);\n"

        s += "var _origTDU=HTMLCanvasElement.prototype.toDataURL;\n"
        s += "HTMLCanvasElement.prototype.toDataURL=_markNative(function toDataURL(t,q){"
        s += "try{var ctx=this.getContext('2d');"
        s += "if(ctx&&this.width>16&&this.height>16){"
        s += "var w=Math.min(this.width,32),h=Math.min(this.height,32);"
        s += "var id=ctx.getImageData(0,0,w,h);var d=id.data;"
        s += "for(var i=0;i<d.length;i+=4){"
        s += "if(_rng()<0.005){d[i]=(d[i]+(_rng()<0.5?1:-1)+256)%256;}"
        s += "}"
        s += "ctx.putImageData(id,0,0);"
        s += "}}catch(e){}"
        s += "return _origTDU.call(this,t,q);"
        s += "},'toDataURL');\n"

        s += "var _origTB=HTMLCanvasElement.prototype.toBlob;\n"
        s += "HTMLCanvasElement.prototype.toBlob=_markNative(function toBlob(cb,t,q){"
        s += "try{var ctx=this.getContext('2d');"
        s += "if(ctx&&this.width>16&&this.height>16){"
        s += "var w=Math.min(this.width,32),h=Math.min(this.height,32);"
        s += "var id=ctx.getImageData(0,0,w,h);var d=id.data;"
        s += "for(var i=0;i<d.length;i+=4){"
        s += "if(_rng()<0.005){d[i]=(d[i]+(_rng()<0.5?1:-1)+256)%256;}"
        s += "}"
        s += "ctx.putImageData(id,0,0);"
        s += "}}catch(e){}"
        s += "return _origTB.call(this,cb,t,q);"
        s += "},'toBlob');\n"

        s += "if(window.OffscreenCanvas){\n"
        s += "var _origOTDU=OffscreenCanvas.prototype.convertToBlob;\n"
        s += "if(_origOTDU){OffscreenCanvas.prototype.convertToBlob=_markNative(function convertToBlob(o){"
        s += "return _origOTDU.call(this,o);"
        s += "},'convertToBlob');}}\n"

        s += "})();\n"
        return s
    }

    private static func webGLSpoof(_ c: FingerprintConfig) -> String {
        let escapedVendor = c.webGLVendor.replacingOccurrences(of: "'", with: "\\'")
        let escapedRenderer = c.webGLRenderer.replacingOccurrences(of: "'", with: "\\'")
        var s = "(function(){\n"
        s += "var _glV='\(escapedVendor)';var _glR='\(escapedRenderer)';\n"
        s += "function _patchGL(P){if(!P)return;\n"
        s += "var _origGP=P.getParameter;\n"
        s += "P.getParameter=_markNative(function getParameter(p){"
        s += "var ext=null;try{ext=this.getExtension('WEBGL_debug_renderer_info');}catch(e){}"
        s += "if(ext){if(p===ext.UNMASKED_VENDOR_WEBGL)return _glV;if(p===ext.UNMASKED_RENDERER_WEBGL)return _glR;}"
        s += "if(p===0x1F00)return _glV;if(p===0x1F01)return _glR;"
        s += "return _origGP.call(this,p);"
        s += "},'getParameter');\n"
        s += "}\n"
        s += "if(window.WebGLRenderingContext)_patchGL(WebGLRenderingContext.prototype);\n"
        s += "if(window.WebGL2RenderingContext)_patchGL(WebGL2RenderingContext.prototype);\n"
        s += "})();\n"
        return s
    }

    private static func audioSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){\n"
        s += "var _as=\(c.audioSeed);var _st=_as;\n"
        s += "function _aprng(){_st=(_st*16807)%2147483647;return(_st-1)/2147483646;}\n"
        s += "if(window.AudioBuffer){\n"
        s += "var _origGCD=AudioBuffer.prototype.getChannelData;\n"
        s += "AudioBuffer.prototype.getChannelData=_markNative(function getChannelData(ch){"
        s += "var d=_origGCD.call(this,ch);"
        s += "for(var i=0;i<d.length;i+=100){d[i]+=(_aprng()-0.5)*0.00005;}"
        s += "return d;"
        s += "},'getChannelData');\n"
        s += "}\n"
        s += "if(window.AudioBuffer&&AudioBuffer.prototype.copyFromChannel){\n"
        s += "var _origCFC=AudioBuffer.prototype.copyFromChannel;\n"
        s += "AudioBuffer.prototype.copyFromChannel=_markNative(function copyFromChannel(dest,ch,off){"
        s += "_origCFC.call(this,dest,ch,off);"
        s += "for(var i=0;i<dest.length;i+=100){dest[i]+=(_aprng()-0.5)*0.00005;}"
        s += "},'copyFromChannel');\n"
        s += "}\n"

        s += "if(window.BaseAudioContext){\n"
        s += "var _origCreateOsc=BaseAudioContext.prototype.createOscillator;\n"
        s += "BaseAudioContext.prototype.createOscillator=_markNative(function createOscillator(){"
        s += "var osc=_origCreateOsc.call(this);"
        s += "var origFreq=osc.frequency.value;"
        s += "osc.frequency.value=origFreq+(_aprng()-0.5)*0.001;"
        s += "return osc;"
        s += "},'createOscillator');}\n"

        s += "})();\n"
        return s
    }

    private static func webRTCSpoof(_ c: FingerprintConfig) -> String {
        guard c.blockWebRTC else { return "" }
        var s = "(function(){\n"
        s += "if(window.RTCPeerConnection){\n"
        s += "var _origRTC=window.RTCPeerConnection;\n"
        s += "window.RTCPeerConnection=_markNative(function RTCPeerConnection(cfg,con){"
        s += "if(cfg&&cfg.iceServers)cfg.iceServers=[];"
        s += "var pc=new _origRTC(cfg,con);\n"
        s += "var _origCO=pc.createOffer.bind(pc);\n"
        s += "pc.createOffer=_markNative(function createOffer(opts){return _origCO(opts).then(function(offer){"
        s += "if(offer&&offer.sdp){"
        s += "offer.sdp=offer.sdp.replace(/([0-9]{1,3}[.]){3}[0-9]{1,3}/g,'0.0.0.0');"
        s += "offer.sdp=offer.sdp.replace(/[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7}/gi,'::');"
        s += "}return offer;});"
        s += "},'createOffer');\n"
        s += "return pc;"
        s += "},'RTCPeerConnection');\n"
        s += "window.RTCPeerConnection.prototype=_origRTC.prototype;\n"
        s += "}\n"

        s += "if(window.webkitRTCPeerConnection){\n"
        s += "window.webkitRTCPeerConnection=window.RTCPeerConnection;\n"
        s += "}\n"

        s += "})();\n"
        return s
    }

    private static func batterySpoof(isSafari: Bool) -> String {
        guard !isSafari else { return "" }
        var s = "(function(){\n"
        s += "if(navigator.getBattery){\n"
        s += "navigator.getBattery=_markNative(function getBattery(){"
        s += "return Promise.resolve({charging:true,chargingTime:0,dischargingTime:Infinity,level:1.0,addEventListener:function(){},removeEventListener:function(){}});"
        s += "},'getBattery');}\n"
        s += "})();\n"
        return s
    }

    private static func storageSpoof() -> String {
        var s = "(function(){\n"
        s += "Object.defineProperty(Navigator.prototype,'cookieEnabled',{get:_markNative(function cookieEnabled(){return true;},'get cookieEnabled'),configurable:true,enumerable:true});\n"
        s += "})();\n"
        return s
    }

    private static func fontSpoof(_ c: FingerprintConfig, isIOS: Bool) -> String {
        var s = "(function(){\n"
        let iosFonts = "['Gill Sans','Helvetica Neue','Menlo','Academy Engraved LET','Al Nile','American Typewriter','Apple Color Emoji','Apple SD Gothic Neo','Arial','Avenir','Baskerville','Chalkboard SE','Coppersmith','Courier New','Damascus','Futura','Georgia','Heiti SC','Hiragino Sans','Kailasa','Marker Felt','Noteworthy','Optima','Palatino','Savoye LET','Symbol','Thonburi','Times New Roman','Trebuchet MS','Verdana','Zapfino']"
        let defaultFonts = "['Arial','Courier New','Georgia','Helvetica','Times New Roman','Trebuchet MS','Verdana']"
        let fonts = isIOS ? iosFonts : defaultFonts

        s += "var _validFonts=new Set(\(fonts));\n"
        s += "if(document.fonts&&document.fonts.check){\n"
        s += "var _origCheck=document.fonts.check.bind(document.fonts);\n"
        s += "document.fonts.check=_markNative(function check(f,t){"
        s += "try{"
        s += "var parts=(f||'').split(',');"
        s += "for(var i=0;i<parts.length;i++){"
        s += "var fam=parts[i].trim().replace(/[\"']/g,'');"
        s += "if(_validFonts.has(fam))return true;}"
        s += "return _origCheck(f,t);"
        s += "}catch(e){return false;}"
        s += "},'check');\n"
        s += "}\n"
        s += "})();\n"
        return s
    }

    private static func cleanupSpoof(isSafari: Bool) -> String {
        var s = "(function(){\n"

        if isSafari {
            s += "try{delete window.chrome;}catch(e){}\n"
            s += "try{if(window.chrome!==undefined){Object.defineProperty(window,'chrome',{get:function(){return undefined;},configurable:true});}}catch(e){}\n"
        }

        s += "var _origGOPD=Object.getOwnPropertyDescriptor;\n"

        s += "try{\n"
        s += "var er=window.Error;"
        s += "var _origStack=_origGOPD(er.prototype,'stack');\n"
        s += "if(_origStack&&_origStack.get){"
        s += "var _origStackGet=_origStack.get;\n"
        s += "Object.defineProperty(er.prototype,'stack',{get:_markNative(function stack(){"
        s += "var s=_origStackGet.call(this);"
        s += "if(typeof s==='string'){"
        s += "s=s.split('\\n').filter(function(l){return l.indexOf('__fp_init')===-1&&l.indexOf('_markNative')===-1;}).join('\\n');"
        s += "}"
        s += "return s;"
        s += "},'get stack'),configurable:true});"
        s += "}}catch(e){}\n"

        s += "try{\n"
        s += "Object.getOwnPropertyDescriptor=_markNative(function getOwnPropertyDescriptor(obj,prop){"
        s += "var d=_origGOPD(obj,prop);"
        s += "if(d&&d.get&&_patchedFns.has(d.get)){"
        s += "d.configurable=true;d.enumerable=true;"
        s += "}"
        s += "return d;"
        s += "},'getOwnPropertyDescriptor');\n"
        s += "}catch(e){}\n"

        s += "})();\n"
        return s
    }
}
