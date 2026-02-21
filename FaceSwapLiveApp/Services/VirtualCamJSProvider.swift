import Foundation

nonisolated enum VirtualCamJSProvider {
    static let patchScript: String = """
    (function(){
    'use strict';
    try{
    if(window.__fslVCamPatched)return;
    window.__fslVCamPatched=true;
    var md=navigator.mediaDevices;
    if(!md||typeof MediaDevices==='undefined')return;

    var origEnum=MediaDevices.prototype.enumerateDevices;
    var origGUM=MediaDevices.prototype.getUserMedia;

    window.__fslVCam={
        active:false,
        replaceAll:true,
        imageSrc:null,
        videoSrc:null,
        _canvas:null,
        _ctx:null,
        _stream:null,
        _videoEl:null,
        _rafId:null
    };

    function initCanvas(){
        var vc=window.__fslVCam;
        if(!vc._canvas){
            vc._canvas=document.createElement('canvas');
            vc._canvas.width=1280;
            vc._canvas.height=720;
            vc._ctx=vc._canvas.getContext('2d');
            vc._ctx.fillStyle='#000';
            vc._ctx.fillRect(0,0,1280,720);
        }
    }

    function cleanup(){
        var vc=window.__fslVCam;
        if(vc._rafId){cancelAnimationFrame(vc._rafId);vc._rafId=null;}
        if(vc._videoEl){try{vc._videoEl.pause();vc._videoEl.removeAttribute('src');vc._videoEl.load();}catch(e){}vc._videoEl=null;}
        if(vc._stream){try{vc._stream.getTracks().forEach(function(t){t.stop();});}catch(e){}vc._stream=null;}
    }

    function patchTrack(stream){
        try{
            var tracks=stream.getVideoTracks();
            if(tracks.length>0){
                var track=tracks[0];
                var origGetSettings=track.getSettings?track.getSettings.bind(track):function(){return{};};
                track.getSettings=function(){
                    var base=origGetSettings();
                    base.deviceId='faceswaplive-vcam';
                    base.groupId='faceswaplive';
                    base.width=1280;
                    base.height=720;
                    base.frameRate=30;
                    base.facingMode='user';
                    base.aspectRatio=1280/720;
                    return base;
                };
                if(track.getCapabilities){
                    track.getCapabilities=function(){
                        return{
                            deviceId:'faceswaplive-vcam',
                            width:{min:1,max:1920},
                            height:{min:1,max:1080},
                            frameRate:{min:1,max:60},
                            facingMode:['user','environment']
                        };
                    };
                }
                try{
                    Object.defineProperty(track,'label',{
                        get:function(){return'FaceSwapLive Camera';},
                        configurable:true
                    });
                }catch(e){}
            }
        }catch(e){}
        return stream;
    }

    function imageStream(){
        return new Promise(function(resolve,reject){
            var vc=window.__fslVCam;
            initCanvas();
            var img=new Image();
            img.crossOrigin='anonymous';
            img.onload=function(){
                var cw=vc._canvas.width,ch=vc._canvas.height;
                var iw=img.naturalWidth,ih=img.naturalHeight;
                var scale=Math.max(cw/iw,ch/ih);
                var dw=iw*scale,dh=ih*scale;
                vc._ctx.drawImage(img,(cw-dw)/2,(ch-dh)/2,dw,dh);
                var s=vc._canvas.captureStream(30);
                vc._stream=s;
                var loop=function(){
                    if(!vc.active)return;
                    vc._ctx.drawImage(img,(cw-dw)/2,(ch-dh)/2,dw,dh);
                    vc._rafId=requestAnimationFrame(loop);
                };
                vc._rafId=requestAnimationFrame(loop);
                resolve(patchTrack(s));
            };
            img.onerror=function(){reject(new DOMException('Image load failed','NotReadableError'));};
            img.src=vc.imageSrc;
        });
    }

    function videoStream(){
        return new Promise(function(resolve,reject){
            var vc=window.__fslVCam;
            initCanvas();
            var fetchUrl=vc.videoSrc;
            var loadVideo=function(src){
                var vid=document.createElement('video');
                vid.setAttribute('playsinline','');
                vid.loop=true;
                vid.muted=true;
                vid.playsInline=true;
                vid.crossOrigin='anonymous';
                vid.src=src;
                vc._videoEl=vid;
                vid.onloadeddata=function(){
                    vid.play().then(function(){
                        var cw=vc._canvas.width,ch=vc._canvas.height;
                        var vw=vid.videoWidth||cw,vh=vid.videoHeight||ch;
                        var scale=Math.max(cw/vw,ch/vh);
                        var dw=vw*scale,dh=vh*scale;
                        vc._ctx.drawImage(vid,(cw-dw)/2,(ch-dh)/2,dw,dh);
                        var s=vc._canvas.captureStream(30);
                        vc._stream=s;
                        var loop=function(){
                            if(!vc.active||vid.paused)return;
                            var cw2=vc._canvas.width,ch2=vc._canvas.height;
                            var vw2=vid.videoWidth||cw2,vh2=vid.videoHeight||ch2;
                            var sc2=Math.max(cw2/vw2,ch2/vh2);
                            var dw2=vw2*sc2,dh2=vh2*sc2;
                            vc._ctx.drawImage(vid,(cw2-dw2)/2,(ch2-dh2)/2,dw2,dh2);
                            vc._rafId=requestAnimationFrame(loop);
                        };
                        vc._rafId=requestAnimationFrame(loop);
                        resolve(patchTrack(s));
                    }).catch(reject);
                };
                vid.onerror=function(){reject(new DOMException('Video load failed','NotReadableError'));};
            };
            fetch(fetchUrl).then(function(r){return r.blob();}).then(function(blob){
                var blobUrl=URL.createObjectURL(blob);
                loadVideo(blobUrl);
            }).catch(function(){
                loadVideo(fetchUrl);
            });
        });
    }

    function getVirtStream(){
        cleanup();
        var vc=window.__fslVCam;
        if(vc.imageSrc)return imageStream();
        if(vc.videoSrc)return videoStream();
        return Promise.reject(new DOMException('No virtual camera source configured','NotFoundError'));
    }

    function addSilentAudio(stream){
        try{
            var ac=new(window.AudioContext||window.webkitAudioContext)();
            var dest=ac.createMediaStreamDestination();
            var osc=ac.createOscillator();
            var gain=ac.createGain();
            gain.gain.value=0;
            osc.connect(gain);
            gain.connect(dest);
            osc.start();
            stream.addTrack(dest.stream.getAudioTracks()[0]);
        }catch(e){}
        return stream;
    }

    MediaDevices.prototype.enumerateDevices=function(){
        var self=this;
        return origEnum.call(self).then(function(devices){
            if(!window.__fslVCam.active)return devices;
            var exists=devices.some(function(d){return d.deviceId==='faceswaplive-vcam';});
            if(!exists){
                devices.push({
                    deviceId:'faceswaplive-vcam',
                    groupId:'faceswaplive',
                    kind:'videoinput',
                    label:'FaceSwapLive Camera',
                    toJSON:function(){return{deviceId:this.deviceId,groupId:this.groupId,kind:this.kind,label:this.label};}
                });
            }
            return devices;
        });
    };

    MediaDevices.prototype.getUserMedia=function(constraints){
        var self=this;
        var vc=window.__fslVCam;
        if(!vc.active||(!vc.imageSrc&&!vc.videoSrc)){
            return origGUM.call(self,constraints);
        }
        var vidC=constraints&&constraints.video;
        if(!vidC)return origGUM.call(self,constraints);

        var isVCam=false;
        if(typeof vidC==='object'){
            var did=vidC.deviceId;
            if(did==='faceswaplive-vcam')isVCam=true;
            if(did&&typeof did==='object'){
                if(did.exact==='faceswaplive-vcam')isVCam=true;
                if(Array.isArray(did.exact)&&did.exact.indexOf('faceswaplive-vcam')>=0)isVCam=true;
                if(Array.isArray(did.ideal)&&did.ideal.indexOf('faceswaplive-vcam')>=0)isVCam=true;
                if(did.ideal==='faceswaplive-vcam')isVCam=true;
            }
        }

        if(vc.replaceAll||isVCam){
            return getVirtStream().then(function(s){
                if(constraints&&constraints.audio)addSilentAudio(s);
                return s;
            });
        }

        if(typeof vidC==='boolean'&&vidC===true&&vc.replaceAll){
            return getVirtStream().then(function(s){
                if(constraints&&constraints.audio)addSilentAudio(s);
                return s;
            });
        }

        return origGUM.call(self,constraints);
    };

    }catch(e){}
    })();
    """
}
