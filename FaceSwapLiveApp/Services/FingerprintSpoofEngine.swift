import Foundation

enum FingerprintSpoofEngine {

    static func safariNormalizationScript() -> String {
        var s = "(function(){\n"
        s += "try{delete window.chrome}catch(e){}\n"
        s += "try{if(typeof window.chrome!=='undefined')Object.defineProperty(window,'chrome',{value:undefined,writable:false,configurable:true})}catch(e){}\n"
        s += "try{if(!navigator.pdfViewerEnabled){Object.defineProperty(Navigator.prototype,'pdfViewerEnabled',{get:function(){return true},configurable:true,enumerable:true})};}catch(e){}\n"
        s += safariPluginsSpoof()
        s += "})();\n"
        return s
    }

    static func spoofScript(for config: FingerprintConfig) -> String {
        let isSafari = config.userAgent.contains("Safari") && !config.userAgent.contains("Chrome")
        let isIOS = config.platform == "iPhone" || config.platform == "iPad"

        var script = "(function(){\n'use strict';\n"
        script += "var _k=Symbol.for('_fp');\nif(window[_k])return;\nObject.defineProperty(window,_k,{value:true});\n"
        script += patchToString(isSafari: isSafari)
        script += navigatorSpoof(config, isSafari: isSafari, isIOS: isIOS)
        script += screenSpoof(config)
        script += timezoneSpoof(config)
        script += canvasSpoof(config)
        script += webGLSpoof(config)
        script += audioSpoof(config)
        script += webRTCSpoof(config)
        script += batterySpoof(isSafari: isSafari)
        script += storageSpoof()
        if isSafari || isIOS {
            script += pluginsSpoof()
        }
        if config.spoofFonts {
            script += fontSpoof(config, isIOS: isIOS)
        }
        script += cleanupSpoof(isSafari: isSafari)
        script += "})();"
        return script
    }

    private static func patchToString(isSafari: Bool) -> String {
        var s = ""
        s += "var _oTS=Function.prototype.toString;\n"
        s += "var _pF=new WeakSet();\n"
        s += "var _pN=new WeakMap();\n"
        s += "function _mk(fn,nm){_pF.add(fn);if(nm)_pN.set(fn,nm);return fn;}\n"

        if isSafari {
            s += "Object.defineProperty(Function.prototype,'toString',{value:_mk(function toString(){"
            s += "if(_pF.has(this)){var n=_pN.get(this)||'';"
            s += "if(n)return'function '+n+'() {\\n    [native code]\\n}';"
            s += "return'function () {\\n    [native code]\\n}';}"
            s += "return _oTS.call(this);},'toString'),writable:true,configurable:true});\n"
        } else {
            s += "Object.defineProperty(Function.prototype,'toString',{value:_mk(function toString(){"
            s += "if(_pF.has(this)){var n=_pN.get(this)||'';"
            s += "if(n)return'function '+n+'() { [native code] }';"
            s += "return'function () { [native code] }';}"
            s += "return _oTS.call(this);},'toString'),writable:true,configurable:true});\n"
        }
        return s
    }

    private static func navigatorSpoof(_ c: FingerprintConfig, isSafari: Bool, isIOS: Bool) -> String {
        let escapedUA = c.userAgent.replacingOccurrences(of: "'", with: "\\'")
        let escapedAppVersion = c.userAgent.replacingOccurrences(of: "Mozilla/", with: "").replacingOccurrences(of: "'", with: "\\'")
        let languagesJS = c.languages.map { "'\($0)'" }.joined(separator: ",")

        var s = "(function(){\n"
        s += "var N=Navigator.prototype;\n"

        s += "var _d=Object.getOwnPropertyDescriptor(N,'userAgent');\n"
        s += "if(_d&&_d.get){"
        s += "Object.defineProperty(N,'userAgent',{get:_mk(function(){return'\(escapedUA)'}),configurable:true,enumerable:true});"
        s += "}else{try{Object.defineProperty(N,'userAgent',{value:'\(escapedUA)',writable:false,configurable:true,enumerable:true})}catch(e){}}\n"

        s += "Object.defineProperty(N,'platform',{get:_mk(function(){return'\(c.platform)'}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(N,'vendor',{get:_mk(function(){return'\(c.vendor)'}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(N,'language',{get:_mk(function(){return'\(c.languages.first ?? "en-US")'}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(N,'languages',{get:_mk(function(){return Object.freeze([\(languagesJS)])}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(N,'hardwareConcurrency',{get:_mk(function(){return \(c.hardwareConcurrency)}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(N,'maxTouchPoints',{get:_mk(function(){return \(c.maxTouchPoints)}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(N,'deviceMemory',{get:_mk(function(){return \(c.deviceMemory)}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(N,'appVersion',{get:_mk(function(){return'\(escapedAppVersion)'}),configurable:true,enumerable:true});\n"

        let dnt = c.doNotTrack
        if dnt == "unspecified" {
            s += "Object.defineProperty(N,'doNotTrack',{get:_mk(function(){return null}),configurable:true,enumerable:true});\n"
        } else {
            s += "Object.defineProperty(N,'doNotTrack',{get:_mk(function(){return'\(dnt)'}),configurable:true,enumerable:true});\n"
        }

        s += "Object.defineProperty(N,'webdriver',{get:_mk(function(){return false}),configurable:true,enumerable:true});\n"

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
            s += "Object.defineProperty(N,'userAgentData',{get:_mk(function(){"
            s += "return{brands:[{brand:'Chromium',version:'131'},{brand:'Not_A Brand',version:'24'}],"
            s += "mobile:\(isMobile),platform:'\(platformOS)',"
            s += "getHighEntropyValues:_mk(function(){return Promise.resolve({architecture:'arm',model:'',platformVersion:'18.3.0',fullVersionList:[{brand:'Chromium',version:'131.0.6778.135'}]})})"
            s += "};}),configurable:true});}\n"
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
            s += "Object.defineProperty(S,'\(prop)',{get:_mk(function(){return \(val)}),configurable:true,enumerable:true});\n"
        }

        s += "Object.defineProperty(window,'devicePixelRatio',{get:_mk(function(){return \(c.pixelRatio)}),configurable:true,enumerable:true});\n"

        let sf = c.screenFrame
        s += "Object.defineProperty(window,'screenX',{get:_mk(function(){return \(sf.x)}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'screenY',{get:_mk(function(){return \(sf.y)}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'outerWidth',{get:_mk(function(){return \(c.screenWidth)}),configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(window,'outerHeight',{get:_mk(function(){return \(c.screenHeight)}),configurable:true,enumerable:true});\n"

        s += "})();\n"
        return s
    }

    private static func timezoneSpoof(_ c: FingerprintConfig) -> String {
        let escapedTZ = c.timezone.replacingOccurrences(of: "'", with: "\\'")
        let locale = c.languages.first ?? "en-US"
        var s = "(function(){\n"
        s += "var _tz='\(escapedTZ)';var _off=\(c.timezoneOffset);\n"

        s += "var _oDTF=Intl.DateTimeFormat;\n"
        s += "var _nDTF=_mk(function DateTimeFormat(loc,opts){"
        s += "opts=Object.assign({},opts||{});"
        s += "if(!opts.timeZone)opts.timeZone=_tz;"
        s += "return new _oDTF(loc,opts);"
        s += "},'DateTimeFormat');\n"

        s += "_nDTF.prototype=_oDTF.prototype;\n"
        s += "_nDTF.supportedLocalesOf=_oDTF.supportedLocalesOf;\n"
        s += "Intl.DateTimeFormat=_nDTF;\n"

        s += "var _oRO=_oDTF.prototype.resolvedOptions;\n"
        s += "_oDTF.prototype.resolvedOptions=_mk(function resolvedOptions(){"
        s += "var r=_oRO.call(this);"
        s += "try{Object.defineProperty(r,'timeZone',{value:_tz,writable:true,configurable:true})}catch(e){r.timeZone=_tz;}"
        s += "return r;"
        s += "});\n"

        s += "Date.prototype.getTimezoneOffset=_mk(function getTimezoneOffset(){return _off;});\n"

        s += "var _oTLS=Date.prototype.toLocaleString;\n"
        s += "Date.prototype.toLocaleString=_mk(function toLocaleString(l,o){"
        s += "o=Object.assign({},o||{});"
        s += "if(!o.timeZone)o.timeZone=_tz;"
        s += "return _oTLS.call(this,l||'\(locale)',o);"
        s += "});\n"

        s += "var _oTLTS=Date.prototype.toLocaleTimeString;\n"
        s += "Date.prototype.toLocaleTimeString=_mk(function toLocaleTimeString(l,o){"
        s += "o=Object.assign({},o||{});"
        s += "if(!o.timeZone)o.timeZone=_tz;"
        s += "return _oTLTS.call(this,l||'\(locale)',o);"
        s += "});\n"

        s += "var _oTLDS=Date.prototype.toLocaleDateString;\n"
        s += "Date.prototype.toLocaleDateString=_mk(function toLocaleDateString(l,o){"
        s += "o=Object.assign({},o||{});"
        s += "if(!o.timeZone)o.timeZone=_tz;"
        s += "return _oTLDS.call(this,l||'\(locale)',o);"
        s += "});\n"

        s += "})();\n"
        return s
    }

    private static func canvasSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){\n"
        s += "var _seed=\(c.canvasSeed);\n"
        s += "function _m32(a){return function(){a|=0;a=a+0x6D2B79F5|0;var t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;}}\n"
        s += "var _rng=_m32(_seed);\n"

        s += "var _oTDU=HTMLCanvasElement.prototype.toDataURL;\n"
        s += "HTMLCanvasElement.prototype.toDataURL=_mk(function toDataURL(t,q){"
        s += "try{var ctx=this.getContext('2d');"
        s += "if(ctx&&this.width>16&&this.height>16){"
        s += "var w=Math.min(this.width,4),h=Math.min(this.height,4);"
        s += "var id=ctx.getImageData(0,0,w,h);var d=id.data;"
        s += "for(var i=0;i<d.length;i+=4){"
        s += "if(_rng()<0.01){d[i]=(d[i]+(_rng()<0.5?1:-1)+256)%256;}"
        s += "}"
        s += "ctx.putImageData(id,0,0);"
        s += "}}catch(e){}"
        s += "return _oTDU.call(this,t,q);"
        s += "});\n"

        s += "var _oTB=HTMLCanvasElement.prototype.toBlob;\n"
        s += "HTMLCanvasElement.prototype.toBlob=_mk(function toBlob(cb,t,q){"
        s += "try{var ctx=this.getContext('2d');"
        s += "if(ctx&&this.width>16&&this.height>16){"
        s += "var w=Math.min(this.width,4),h=Math.min(this.height,4);"
        s += "var id=ctx.getImageData(0,0,w,h);var d=id.data;"
        s += "for(var i=0;i<d.length;i+=4){"
        s += "if(_rng()<0.01){d[i]=(d[i]+(_rng()<0.5?1:-1)+256)%256;}"
        s += "}"
        s += "ctx.putImageData(id,0,0);"
        s += "}}catch(e){}"
        s += "return _oTB.call(this,cb,t,q);"
        s += "});\n"

        s += "})();\n"
        return s
    }

    private static func webGLSpoof(_ c: FingerprintConfig) -> String {
        let escapedVendor = c.webGLVendor.replacingOccurrences(of: "'", with: "\\'")
        let escapedRenderer = c.webGLRenderer.replacingOccurrences(of: "'", with: "\\'")
        var s = "(function(){\n"
        s += "var _glV='\(escapedVendor)';var _glR='\(escapedRenderer)';\n"
        s += "function _pGL(P){if(!P)return;\n"
        s += "var _oGP=P.getParameter;\n"
        s += "P.getParameter=_mk(function getParameter(p){"
        s += "var ext=null;try{ext=this.getExtension('WEBGL_debug_renderer_info')}catch(e){}"
        s += "if(ext){if(p===ext.UNMASKED_VENDOR_WEBGL)return _glV;if(p===ext.UNMASKED_RENDERER_WEBGL)return _glR;}"
        s += "if(p===0x1F00)return _glV;if(p===0x1F01)return _glR;"
        s += "return _oGP.call(this,p);"
        s += "})}\n"
        s += "if(window.WebGLRenderingContext)_pGL(WebGLRenderingContext.prototype);\n"
        s += "if(window.WebGL2RenderingContext)_pGL(WebGL2RenderingContext.prototype);\n"
        s += "})();\n"
        return s
    }

    private static func audioSpoof(_ c: FingerprintConfig) -> String {
        var s = "(function(){\n"
        s += "var _as=\(c.audioSeed);var _st=_as;\n"
        s += "function _arng(){_st=(_st*16807)%2147483647;return(_st-1)/2147483646;}\n"
        s += "if(window.AudioBuffer){\n"
        s += "var _oGCD=AudioBuffer.prototype.getChannelData;\n"
        s += "AudioBuffer.prototype.getChannelData=_mk(function getChannelData(ch){"
        s += "var d=_oGCD.call(this,ch);"
        s += "for(var i=0;i<d.length;i+=100){d[i]+=(_arng()-0.5)*0.00001;}"
        s += "return d;"
        s += "})}\n"
        s += "if(window.AudioBuffer&&AudioBuffer.prototype.copyFromChannel){\n"
        s += "var _oCFC=AudioBuffer.prototype.copyFromChannel;\n"
        s += "AudioBuffer.prototype.copyFromChannel=_mk(function copyFromChannel(dest,ch,off){"
        s += "_oCFC.call(this,dest,ch,off);"
        s += "for(var i=0;i<dest.length;i+=100){dest[i]+=(_arng()-0.5)*0.00001;}"
        s += "})}\n"
        s += "if(window.BaseAudioContext){\n"
        s += "var _oCO=BaseAudioContext.prototype.createOscillator;\n"
        s += "BaseAudioContext.prototype.createOscillator=_mk(function createOscillator(){"
        s += "var osc=_oCO.call(this);"
        s += "var of2=osc.frequency.value;"
        s += "osc.frequency.value=of2+(_arng()-0.5)*0.0001;"
        s += "return osc;"
        s += "})}\n"
        s += "})();\n"
        return s
    }

    private static func webRTCSpoof(_ c: FingerprintConfig) -> String {
        guard c.blockWebRTC else { return "" }
        var s = "(function(){\n"
        s += "if(window.RTCPeerConnection){\n"
        s += "var _oRTC=window.RTCPeerConnection;\n"
        s += "window.RTCPeerConnection=_mk(function RTCPeerConnection(cfg,con){"
        s += "if(cfg&&cfg.iceServers)cfg.iceServers=[];"
        s += "var pc=new _oRTC(cfg,con);\n"
        s += "var _oCO2=pc.createOffer.bind(pc);\n"
        s += "pc.createOffer=_mk(function createOffer(opts){return _oCO2(opts).then(function(offer){"
        s += "if(offer&&offer.sdp){"
        s += "offer.sdp=offer.sdp.replace(/([0-9]{1,3}[.]){3}[0-9]{1,3}/g,'0.0.0.0');"
        s += "offer.sdp=offer.sdp.replace(/[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7}/gi,'::');"
        s += "}return offer;});"
        s += "});\n"
        s += "return pc;"
        s += "});\n"
        s += "window.RTCPeerConnection.prototype=_oRTC.prototype;\n"
        s += "}\n"
        s += "if(window.webkitRTCPeerConnection){"
        s += "window.webkitRTCPeerConnection=window.RTCPeerConnection;}\n"
        s += "})();\n"
        return s
    }

    private static func batterySpoof(isSafari: Bool) -> String {
        guard !isSafari else { return "" }
        var s = "(function(){\n"
        s += "if(navigator.getBattery){\n"
        s += "navigator.getBattery=_mk(function getBattery(){"
        s += "return Promise.resolve({charging:true,chargingTime:0,dischargingTime:Infinity,level:1.0,addEventListener:function(){},removeEventListener:function(){}});"
        s += "})}\n"
        s += "})();\n"
        return s
    }

    private static func storageSpoof() -> String {
        var s = "(function(){\n"
        s += "Object.defineProperty(Navigator.prototype,'cookieEnabled',{get:_mk(function(){return true}),configurable:true,enumerable:true});\n"
        s += "})();\n"
        return s
    }

    private static func safariPluginsSpoof() -> String {
        var s = "(function(){\n"
        s += "try{\n"
        s += "if(navigator.plugins&&navigator.plugins.length===0){\n"
        s += "var _pNames=['PDF Viewer','Chrome PDF Viewer','Chromium PDF Viewer','Microsoft Edge PDF Viewer','WebKit built-in PDF'];\n"
        s += "var _fakePlugins=[];\n"
        s += "for(var i=0;i<_pNames.length;i++){\n"
        s += "var mt1={type:'application/pdf',suffixes:'pdf',description:'Portable Document Format',enabledPlugin:null};\n"
        s += "var mt2={type:'text/pdf',suffixes:'pdf',description:'Portable Document Format',enabledPlugin:null};\n"
        s += "var pl={name:_pNames[i],description:'Portable Document Format',filename:'internal-pdf-viewer',length:2,0:mt1,1:mt2,item:function(j){return this[j]||null},namedItem:function(n){for(var k=0;k<this.length;k++){if(this[k]&&this[k].type===n)return this[k]}return null}};\n"
        s += "mt1.enabledPlugin=pl;mt2.enabledPlugin=pl;\n"
        s += "_fakePlugins.push(pl);}\n"
        s += "var _pa={length:_fakePlugins.length};\n"
        s += "for(var j=0;j<_fakePlugins.length;j++){_pa[j]=_fakePlugins[j];_pa[_fakePlugins[j].name]=_fakePlugins[j];}\n"
        s += "_pa.item=function(i){return this[i]||null};\n"
        s += "_pa.namedItem=function(n){return this[n]||null};\n"
        s += "_pa.refresh=function(){};\n"
        s += "Object.defineProperty(Navigator.prototype,'plugins',{get:function(){return _pa},configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(Navigator.prototype,'mimeTypes',{get:function(){var mt={length:_fakePlugins.length*2};var idx=0;for(var i=0;i<_fakePlugins.length;i++){mt[idx++]=_fakePlugins[i][0];mt[idx++]=_fakePlugins[i][1]}mt.item=function(i){return this[i]||null};mt.namedItem=function(n){for(var k=0;k<this.length;k++){if(this[k]&&this[k].type===n)return this[k]}return null};return mt},configurable:true,enumerable:true});\n"
        s += "Object.defineProperty(Navigator.prototype,'pdfViewerEnabled',{get:function(){return true},configurable:true,enumerable:true});\n"
        s += "}\n"
        s += "}catch(e){}\n"
        s += "})();\n"
        return s
    }

    private static func pluginsSpoof() -> String {
        return safariPluginsSpoof()
    }

    private static func fontSpoof(_ c: FingerprintConfig, isIOS: Bool) -> String {
        var s = "(function(){\n"
        let iosFonts = "['Gill Sans','Helvetica Neue','Menlo','Academy Engraved LET','Al Nile','American Typewriter','Apple Color Emoji','Apple SD Gothic Neo','Arial','Avenir','Baskerville','Chalkboard SE','Coppersmith','Courier New','Damascus','Futura','Georgia','Heiti SC','Hiragino Sans','Kailasa','Marker Felt','Noteworthy','Optima','Palatino','Savoye LET','Symbol','Thonburi','Times New Roman','Trebuchet MS','Verdana','Zapfino']"
        let defaultFonts = "['Arial','Courier New','Georgia','Helvetica','Times New Roman','Trebuchet MS','Verdana']"
        let fonts = isIOS ? iosFonts : defaultFonts

        s += "var _vF=new Set(\(fonts));\n"
        s += "if(document.fonts&&document.fonts.check){\n"
        s += "var _oCheck=document.fonts.check.bind(document.fonts);\n"
        s += "document.fonts.check=_mk(function check(f,t){"
        s += "try{"
        s += "var parts=(f||'').split(',');"
        s += "for(var i=0;i<parts.length;i++){"
        s += "var fam=parts[i].trim().replace(/[\"']/g,'');"
        s += "if(_vF.has(fam))return true;}"
        s += "return _oCheck(f,t);"
        s += "}catch(e){return false;}"
        s += "})}\n"
        s += "})();\n"
        return s
    }

    private static func cleanupSpoof(isSafari: Bool) -> String {
        var s = "(function(){\n"
        if isSafari {
            s += "try{delete window.chrome}catch(e){}\n"
            s += "try{if(typeof window.chrome!=='undefined')Object.defineProperty(window,'chrome',{value:undefined,writable:false,configurable:true})}catch(e){}\n"
        }
        s += "})();\n"
        return s
    }
}
