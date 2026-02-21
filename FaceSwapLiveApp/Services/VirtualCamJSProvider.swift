import Foundation

nonisolated enum VirtualCamJSProvider {
    static let patchScript: String = """
    (function(){
    'use strict';
    try{
    if(window.__fslVCamPatched)return;
    window.__fslVCamPatched=true;
    if(typeof MediaDevices==='undefined'||!navigator.mediaDevices)return;

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
        }
    }

    function cleanup(){
        var vc=window.__fslVCam;
        if(vc._rafId){cancelAnimationFrame(vc._rafId);vc._rafId=null;}
        if(vc._videoEl){try{vc._videoEl.pause();vc._videoEl.removeAttribute('src');vc._videoEl.load();}catch(e){}vc._videoEl=null;}
        if(vc._stream){try{vc._stream.getTracks().forEach(function(t){t.stop();});}catch(e){}vc._stream=null;}
    }

    function imageStream(){
        return new Promise(function(resolve,reject){
            var vc=window.__fslVCam;
            initCanvas();
            var img=new Image();
            img.onload=function(){
                var loop=function(){
                    if(!vc.active)return;
                    var cw=vc._canvas.width,ch=vc._canvas.height;
                    var iw=img.naturalWidth,ih=img.naturalHeight;
                    var scale=Math.max(cw/iw,ch/ih);
                    var dw=iw*scale,dh=ih*scale;
                    vc._ctx.drawImage(img,(cw-dw)/2,(ch-dh)/2,dw,dh);
                    vc._rafId=requestAnimationFrame(loop);
                };
                loop();
                var s=vc._canvas.captureStream(30);
                vc._stream=s;
                resolve(s);
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
                vid.src=src;
                vc._videoEl=vid;
                vid.onloadeddata=function(){
                    vid.play().then(function(){
                        var loop=function(){
                            if(!vc.active||vid.paused)return;
                            var cw=vc._canvas.width,ch=vc._canvas.height;
                            var vw=vid.videoWidth||cw,vh=vid.videoHeight||ch;
                            var scale=Math.max(cw/vw,ch/vh);
                            var dw=vw*scale,dh=vh*scale;
                            vc._ctx.drawImage(vid,(cw-dw)/2,(ch-dh)/2,dw,dh);
                            vc._rafId=requestAnimationFrame(loop);
                        };
                        loop();
                        var s=vc._canvas.captureStream(30);
                        vc._stream=s;
                        resolve(s);
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
        return origEnum.call(navigator.mediaDevices).then(function(devices){
            if(window.__fslVCam.active){
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
            }
            return devices;
        });
    };

    MediaDevices.prototype.getUserMedia=function(constraints){
        var vc=window.__fslVCam;
        if(!vc.active||(!vc.imageSrc&&!vc.videoSrc)){
            return origGUM.call(navigator.mediaDevices,constraints);
        }
        var vidC=constraints&&constraints.video;
        if(!vidC)return origGUM.call(navigator.mediaDevices,constraints);

        if(typeof vidC==='boolean'){
            if(vc.replaceAll){
                return getVirtStream().then(function(s){if(constraints.audio)addSilentAudio(s);return s;});
            }
            return origGUM.call(navigator.mediaDevices,constraints);
        }

        var did=vidC.deviceId;
        var isVCam=false;
        if(did==='faceswaplive-vcam')isVCam=true;
        if(did&&typeof did==='object'&&did.exact==='faceswaplive-vcam')isVCam=true;
        if(did&&typeof did==='object'&&Array.isArray(did.exact)&&did.exact.indexOf('faceswaplive-vcam')>=0)isVCam=true;
        if(did&&typeof did==='object'&&Array.isArray(did.ideal)&&did.ideal.indexOf('faceswaplive-vcam')>=0)isVCam=true;

        if(vc.replaceAll||isVCam){
            return getVirtStream().then(function(s){if(constraints&&constraints.audio)addSilentAudio(s);return s;});
        }
        return origGUM.call(navigator.mediaDevices,constraints);
    };

    }catch(e){}
    })();
    """
}
