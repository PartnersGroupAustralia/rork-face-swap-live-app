import Foundation

nonisolated enum FingerprintSpoofEngine {
    static func spoofScript(for config: FingerprintConfig) -> String {
        let languagesArrayJS = config.languages.map { "'\($0)'" }.joined(separator: ",")

        return """
        (function(){
        'use strict';
        if(window.__adSpoofed)return;
        window.__adSpoofed=true;

        var _dp=Object.defineProperty;

        function safeDefine(obj,prop,val){
            try{_dp(obj,prop,{get:function(){return val;},configurable:true,enumerable:true});}catch(e){}
        }

        \(navigatorSpoof(config, languagesArrayJS: languagesArrayJS))

        \(screenSpoof(config))

        \(timezoneSpoof(config))

        \(canvasSpoof(config))

        \(webGLSpoof(config))

        \(audioSpoof(config))

        \(webRTCSpoof(config))

        \(pluginsSpoof())

        \(fontSpoof(config))

        \(automationSpoof())

        \(permissionsSpoof())

        })();
        """
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

        return """
        (function(){
            var navProps={
                userAgent:'\(escapedUA)',
                platform:'\(c.platform)',
                vendor:'\(c.vendor)',
                language:'\(c.languages.first ?? "en-US")',
                hardwareConcurrency:\(c.hardwareConcurrency),
                maxTouchPoints:\(c.maxTouchPoints),
                appVersion:'\(escapedAppVersion)'
            };
            for(var k in navProps){
                safeDefine(Navigator.prototype,k,navProps[k]);
            }
            try{
                _dp(Navigator.prototype,'languages',{get:function(){return Object.freeze([\(languagesArrayJS)]);},configurable:true,enumerable:true});
            }catch(e){}
            try{
                _dp(Navigator.prototype,'deviceMemory',{get:function(){return \(c.deviceMemory);},configurable:true,enumerable:true});
            }catch(e){}
            var dnt='\(c.doNotTrack)';
            if(dnt==='unspecified'){
                safeDefine(Navigator.prototype,'doNotTrack',null);
            }else{
                safeDefine(Navigator.prototype,'doNotTrack',dnt);
            }
            if(Navigator.prototype.userAgentData){
                try{
                    _dp(Navigator.prototype,'userAgentData',{get:function(){
                        return{
                            brands:[{brand:'Not_A Brand',version:'8'},{brand:'Chromium',version:'131'}],
                            mobile:\(isMobile),
                            platform:'\(platformOS)',
                            getHighEntropyValues:function(){return Promise.resolve({architecture:'arm',model:'',platformVersion:'18.3.0',fullVersionList:[{brand:'Chromium',version:'131.0.6778.135'}]});}
                        };
                    },configurable:true});
                }catch(e){}
            }
        })();
        """
    }

    private static func screenSpoof(_ c: FingerprintConfig) -> String {
        return """
        (function(){
            safeDefine(Screen.prototype,'width',\(c.screenWidth));
            safeDefine(Screen.prototype,'height',\(c.screenHeight));
            safeDefine(Screen.prototype,'availWidth',\(c.availWidth));
            safeDefine(Screen.prototype,'availHeight',\(c.availHeight));
            safeDefine(Screen.prototype,'colorDepth',\(c.colorDepth));
            safeDefine(Screen.prototype,'pixelDepth',\(c.colorDepth));
            safeDefine(window,'devicePixelRatio',\(c.pixelRatio));
            safeDefine(window,'innerWidth',\(c.screenWidth));
            safeDefine(window,'innerHeight',\(c.screenHeight));
            safeDefine(window,'outerWidth',\(c.screenWidth));
            safeDefine(window,'outerHeight',\(c.screenHeight));
        })();
        """
    }

    private static func timezoneSpoof(_ c: FingerprintConfig) -> String {
        return """
        (function(){
            var tz='\(c.timezone)';
            var off=\(c.timezoneOffset);
            var origDTF=Intl.DateTimeFormat;
            var newDTF=function(loc,opts){
                opts=Object.assign({},opts||{});
                if(!opts.timeZone)opts.timeZone=tz;
                return new origDTF(loc,opts);
            };
            newDTF.prototype=origDTF.prototype;
            newDTF.supportedLocalesOf=origDTF.supportedLocalesOf;
            try{Intl.DateTimeFormat=newDTF;}catch(e){}
            try{
                var origResolve=origDTF.prototype.resolvedOptions;
                origDTF.prototype.resolvedOptions=function(){
                    var r=origResolve.call(this);
                    r.timeZone=tz;
                    return r;
                };
            }catch(e){}
            var origGetTZO=Date.prototype.getTimezoneOffset;
            Date.prototype.getTimezoneOffset=function(){return off;};
            Date.prototype.getTimezoneOffset.toString=function(){return'function getTimezoneOffset() { [native code] }';};
        })();
        """
    }

    private static func canvasSpoof(_ c: FingerprintConfig) -> String {
        return """
        (function(){
            var seed=\(c.canvasSeed);
            function m32(a){return function(){a|=0;a=a+0x6D2B79F5|0;var t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
            var rng=m32(seed);
            var origTDU=HTMLCanvasElement.prototype.toDataURL;
            HTMLCanvasElement.prototype.toDataURL=function(t,q){
                try{
                    var ctx=this.getContext('2d');
                    if(ctx&&this.width>0&&this.height>0){
                        var w=Math.min(this.width,64),h=Math.min(this.height,64);
                        var id=ctx.getImageData(0,0,w,h);
                        var d=id.data;
                        for(var i=0;i<d.length;i+=4){
                            if(rng()<0.01){d[i]^=(rng()*2|0);d[i+1]^=(rng()*2|0);}
                        }
                        ctx.putImageData(id,0,0);
                    }
                }catch(e){}
                return origTDU.call(this,t,q);
            };
            HTMLCanvasElement.prototype.toDataURL.toString=function(){return'function toDataURL() { [native code] }';};
            var origTB=HTMLCanvasElement.prototype.toBlob;
            HTMLCanvasElement.prototype.toBlob=function(cb,t,q){
                try{
                    var ctx=this.getContext('2d');
                    if(ctx&&this.width>0&&this.height>0){
                        var w=Math.min(this.width,64),h=Math.min(this.height,64);
                        var id=ctx.getImageData(0,0,w,h);
                        var d=id.data;
                        for(var i=0;i<d.length;i+=4){
                            if(rng()<0.01){d[i]^=(rng()*2|0);d[i+1]^=(rng()*2|0);}
                        }
                        ctx.putImageData(id,0,0);
                    }
                }catch(e){}
                return origTB.call(this,cb,t,q);
            };
            HTMLCanvasElement.prototype.toBlob.toString=function(){return'function toBlob() { [native code] }';};
        })();
        """
    }

    private static func webGLSpoof(_ c: FingerprintConfig) -> String {
        let escapedVendor = c.webGLVendor.replacingOccurrences(of: "'", with: "\\'")
        let escapedRenderer = c.webGLRenderer.replacingOccurrences(of: "'", with: "\\'")
        return """
        (function(){
            var vend='\(escapedVendor)';
            var rend='\(escapedRenderer)';
            function patchGL(Proto){
                if(!Proto)return;
                var origGP=Proto.getParameter;
                Proto.getParameter=function(p){
                    var ext=null;
                    try{ext=this.getExtension('WEBGL_debug_renderer_info');}catch(e){}
                    if(ext){
                        if(p===ext.UNMASKED_VENDOR_WEBGL)return vend;
                        if(p===ext.UNMASKED_RENDERER_WEBGL)return rend;
                    }
                    if(p===0x1F00)return vend;
                    if(p===0x1F01)return rend;
                    return origGP.call(this,p);
                };
                Proto.getParameter.toString=function(){return'function getParameter() { [native code] }';};
            }
            if(window.WebGLRenderingContext)patchGL(WebGLRenderingContext.prototype);
            if(window.WebGL2RenderingContext)patchGL(WebGL2RenderingContext.prototype);
        })();
        """
    }

    private static func audioSpoof(_ c: FingerprintConfig) -> String {
        return """
        (function(){
            var seed=\(c.audioSeed);
            var s=seed;
            function prng(){s=(s*16807)%2147483647;return(s-1)/2147483646;}
            if(window.AudioBuffer){
                var origGCD=AudioBuffer.prototype.getChannelData;
                AudioBuffer.prototype.getChannelData=function(ch){
                    var d=origGCD.call(this,ch);
                    for(var i=0;i<d.length;i+=100){d[i]+=(prng()-0.5)*0.0001;}
                    return d;
                };
                AudioBuffer.prototype.getChannelData.toString=function(){return'function getChannelData() { [native code] }';};
            }
            if(window.AudioBuffer&&AudioBuffer.prototype.copyFromChannel){
                var origCFC=AudioBuffer.prototype.copyFromChannel;
                AudioBuffer.prototype.copyFromChannel=function(dest,ch,off){
                    origCFC.call(this,dest,ch,off);
                    for(var i=0;i<dest.length;i+=100){dest[i]+=(prng()-0.5)*0.0001;}
                };
                AudioBuffer.prototype.copyFromChannel.toString=function(){return'function copyFromChannel() { [native code] }';};
            }
        })();
        """
    }

    private static func webRTCSpoof(_ c: FingerprintConfig) -> String {
        guard c.blockWebRTC else { return "" }
        return """
        (function(){
            if(window.RTCPeerConnection){
                var origRTC=window.RTCPeerConnection;
                window.RTCPeerConnection=function(cfg,con){
                    if(cfg&&cfg.iceServers)cfg.iceServers=[];
                    var pc=new origRTC(cfg,con);
                    var origCO=pc.createOffer.bind(pc);
                    pc.createOffer=function(opts){
                        return origCO(opts).then(function(offer){
                            if(offer&&offer.sdp){
                                offer.sdp=offer.sdp.replace(/([0-9]{1,3}\\.){3}[0-9]{1,3}/g,'0.0.0.0');
                                offer.sdp=offer.sdp.replace(/[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7}/gi,'::');
                            }
                            return offer;
                        });
                    };
                    return pc;
                };
                window.RTCPeerConnection.prototype=origRTC.prototype;
                window.RTCPeerConnection.toString=function(){return'function RTCPeerConnection() { [native code] }';};
            }
        })();
        """
    }

    private static func pluginsSpoof() -> String {
        return """
        (function(){
            safeDefine(Navigator.prototype,'plugins',[]);
            safeDefine(Navigator.prototype,'mimeTypes',[]);
            try{
                _dp(Navigator.prototype,'pdfViewerEnabled',{get:function(){return false;},configurable:true});
            }catch(e){}
        })();
        """
    }

    private static func fontSpoof(_ c: FingerprintConfig) -> String {
        guard c.spoofFonts else { return "" }
        return """
        (function(){
            var baseFonts=['Arial','Courier New','Georgia','Times New Roman','Verdana','Helvetica','Trebuchet MS'];
            if(document.fonts&&document.fonts.check){
                var origCheck=document.fonts.check.bind(document.fonts);
                document.fonts.check=function(f,t){
                    var fam=(f||'').toLowerCase();
                    var isBase=baseFonts.some(function(b){return fam.indexOf(b.toLowerCase())>=0;});
                    if(isBase)return true;
                    return false;
                };
                document.fonts.check.toString=function(){return'function check() { [native code] }';};
            }
        })();
        """
    }

    private static func automationSpoof() -> String {
        return """
        (function(){
            safeDefine(Navigator.prototype,'webdriver',false);
            try{delete Navigator.prototype.webdriver;}catch(e){}
            safeDefine(Navigator.prototype,'webdriver',undefined);
            try{
                if(window.chrome===undefined){
                    window.chrome={runtime:{},csi:function(){return{};}};
                }
            }catch(e){}
        })();
        """
    }

    private static func permissionsSpoof() -> String {
        return """
        (function(){
            if(navigator.permissions&&navigator.permissions.query){
                var origQuery=navigator.permissions.query.bind(navigator.permissions);
                navigator.permissions.query=function(desc){
                    if(desc&&desc.name==='notifications'){
                        return Promise.resolve({state:'prompt',onchange:null});
                    }
                    return origQuery(desc);
                };
                navigator.permissions.query.toString=function(){return'function query() { [native code] }';};
            }
        })();
        """
    }
}
