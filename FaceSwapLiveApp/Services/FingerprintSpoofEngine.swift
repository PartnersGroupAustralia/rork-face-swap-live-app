import Foundation

enum FingerprintSpoofEngine {

    static func normalizationScript() -> String {
        return """
        (function(){
            var N=function(){};
            var oTS=Function.prototype.toString;
            var nativeMap=new WeakMap();
            var tsFn=function toString(){if(nativeMap.has(this)){return nativeMap.get(this)}return oTS.call(this)};
            nativeMap.set(tsFn,'function toString() { [native code] }');
            Function.prototype.toString=tsFn;
            function mn(f,n){nativeMap.set(f,'function '+n+'() { [native code] }');}

            try{if(typeof window.chrome!=='undefined'){Object.defineProperty(window,'chrome',{value:undefined,writable:false,configurable:true,enumerable:false});try{delete window.chrome}catch(e){}}}catch(e){}

            try{
                if(window.webkit&&window.webkit.messageHandlers){
                    var wk=window.webkit;
                    try{Object.defineProperty(wk,'messageHandlers',{value:undefined,writable:false,configurable:true,enumerable:false})}catch(e){}
                    try{Object.defineProperty(window,'webkit',{value:undefined,writable:false,configurable:true,enumerable:false})}catch(e){}
                }
            }catch(e){}

            try{
                var pdfGet=function pdfViewerEnabled(){return true};
                mn(pdfGet,'get pdfViewerEnabled');
                Object.defineProperty(Navigator.prototype,'pdfViewerEnabled',{get:pdfGet,configurable:true,enumerable:true});
            }catch(e){}

            try{
                function MimeType(t,d,s){this.type=t;this.description=d;this.suffixes=s;this.enabledPlugin=null;}
                MimeType.prototype.toString=function(){return '[object MimeType]'};
                mn(MimeType.prototype.toString,'toString');

                function Plugin(n,d,fn,mt){
                    this.name=n;this.description=d;this.filename=fn;this.length=mt.length;
                    for(var i=0;i<mt.length;i++){this[i]=mt[i];mt[i].enabledPlugin=this;}
                }
                Plugin.prototype.item=function item(i){return this[i]||null};
                Plugin.prototype.namedItem=function namedItem(n){for(var i=0;i<this.length;i++){if(this[i].type===n)return this[i]}return null};
                Plugin.prototype.toString=function(){return '[object Plugin]'};
                mn(Plugin.prototype.item,'item');
                mn(Plugin.prototype.namedItem,'namedItem');
                mn(Plugin.prototype.toString,'toString');

                var pdfMimes=[
                    new MimeType('application/pdf','Portable Document Format','pdf'),
                    new MimeType('text/pdf','Portable Document Format','pdf')
                ];
                var pluginData=[
                    ['PDF Viewer','Portable Document Format','internal-pdf-viewer'],
                    ['Chrome PDF Viewer','Portable Document Format','internal-pdf-viewer'],
                    ['Chromium PDF Viewer','Portable Document Format','internal-pdf-viewer'],
                    ['Microsoft Edge PDF Viewer','Portable Document Format','internal-pdf-viewer'],
                    ['WebKit built-in PDF','Portable Document Format','internal-pdf-viewer']
                ];
                var plugins=[];
                for(var p=0;p<pluginData.length;p++){
                    var pd=pluginData[p];
                    var mimes=[
                        new MimeType('application/pdf','Portable Document Format','pdf'),
                        new MimeType('text/pdf','Portable Document Format','pdf')
                    ];
                    plugins.push(new Plugin(pd[0],pd[1],pd[2],mimes));
                }

                var pluginsObj={length:plugins.length};
                for(var i=0;i<plugins.length;i++){
                    pluginsObj[i]=plugins[i];
                    pluginsObj[plugins[i].name]=plugins[i];
                }
                pluginsObj.item=function item(i){return pluginsObj[i]||null};
                pluginsObj.namedItem=function namedItem(n){return pluginsObj[n]||null};
                pluginsObj.refresh=function refresh(){};
                pluginsObj[Symbol.iterator]=function(){var idx=0;var self=this;return{next:function(){if(idx<self.length){return{value:self[idx++],done:false}}return{done:true}}}};
                mn(pluginsObj.item,'item');
                mn(pluginsObj.namedItem,'namedItem');
                mn(pluginsObj.refresh,'refresh');

                var pluginsGet=function plugins(){return pluginsObj};
                mn(pluginsGet,'get plugins');
                Object.defineProperty(Navigator.prototype,'plugins',{get:pluginsGet,configurable:true,enumerable:true});

                var allMimes=[];
                for(var j=0;j<plugins.length;j++){
                    for(var k=0;k<plugins[j].length;k++){
                        allMimes.push(plugins[j][k]);
                    }
                }
                var mimesObj={length:allMimes.length};
                for(var m=0;m<allMimes.length;m++){
                    mimesObj[m]=allMimes[m];
                    mimesObj[allMimes[m].type]=allMimes[m];
                }
                mimesObj.item=function item(i){return mimesObj[i]||null};
                mimesObj.namedItem=function namedItem(n){return mimesObj[n]||null};
                mimesObj[Symbol.iterator]=function(){var idx=0;var self=this;return{next:function(){if(idx<self.length){return{value:self[idx++],done:false}}return{done:true}}}};
                mn(mimesObj.item,'item');
                mn(mimesObj.namedItem,'namedItem');

                var mimesGet=function mimeTypes(){return mimesObj};
                mn(mimesGet,'get mimeTypes');
                Object.defineProperty(Navigator.prototype,'mimeTypes',{get:mimesGet,configurable:true,enumerable:true});
            }catch(e){}

            try{
                var vendorGet=function vendor(){return 'Apple Computer, Inc.'};
                mn(vendorGet,'get vendor');
                Object.defineProperty(Navigator.prototype,'vendor',{get:vendorGet,configurable:true,enumerable:true});
            }catch(e){}

            try{
                var odGet=function openDatabase(){return undefined};
                mn(odGet,'get openDatabase');
                Object.defineProperty(Navigator.prototype,'openDatabase',{value:undefined,writable:false,configurable:true,enumerable:false});
            }catch(e){}

            try{
                if(typeof window.__firefox!=='undefined'){delete window.__firefox}
                if(typeof window.__crWeb!=='undefined'){delete window.__crWeb}
                if(typeof window.__gCrWeb!=='undefined'){delete window.__gCrWeb}
            }catch(e){}

            try{
                var origGetOwnPropDesc=Object.getOwnPropertyDescriptor;
                var propsToHide={'Navigator.prototype.plugins':true,'Navigator.prototype.mimeTypes':true,'Navigator.prototype.pdfViewerEnabled':true,'Navigator.prototype.vendor':true};
            }catch(e){}
        })();
        """
    }

    static func customUserAgent(for config: FingerprintConfig) -> String? {
        switch config.mode {
        case .defaultSafari:
            return nil
        case .stealthSafari:
            if !config.userAgent.isEmpty {
                return config.userAgent
            }
            return nil
        }
    }
}
