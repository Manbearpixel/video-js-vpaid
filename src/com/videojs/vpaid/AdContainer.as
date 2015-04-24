package com.videojs.vpaid {
    
    import com.videojs.*;
    import com.videojs.structs.ExternalErrorEventName;
    import com.videojs.structs.ExternalEventName;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.*;
    /*import flash.net.URLRequest;*/
	import flash.net.*;
	import flash.external.ExternalInterface;
    import flash.system.LoaderContext;
    import com.videojs.vpaid.events.VPAIDEvent;
    import flash.media.SoundMixer;
    import flash.media.SoundTransform;    
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    
    public class AdContainer extends Sprite {
        
        private var _model: VideoJSModel;
        private var _src: String;
        private var _vpaidAd: *;
        private var _isPlaying:Boolean = false;
        private var _isPaused:Boolean = true;
        private var _hasEnded:Boolean = false;
        private var _loadStarted:Boolean = false;

        private var _muteTimer:Timer = new Timer(300);
        private var _debug:Boolean = false;


        public function AdContainer(){
            _model = VideoJSModel.getInstance();
            _muteTimer.addEventListener(TimerEvent.TIMER, muteHandler);
        }
		
        private function muteHandler(evt:TimerEvent):void {
            SoundMixer.soundTransform = new SoundTransform(0);
            SoundMixer.stopAll();
            console('muteHandler');
        }

        public function alwaysMuted(bool:Boolean):void {
            if (bool) {
                _muteTimer.start();
            }
        }

		public function console(mixedVar:*):void {
            if (_debug) {
    			//ExternalInterface.call("console.info", "[ActionScript] [AdContainer]: ");
    			//ExternalInterface.call("console.group");
    			ExternalInterface.call("console.log", "[ActionScript] [AdContainer]: " + mixedVar);
    			//ExternalInterface.call("console.groupEnd");
            }
		}
		
		public function testFunction():String {
			return "You got me!";
		}

        public function get hasActiveAdAsset(): Boolean {
            return _vpaidAd != null;
        }

        public function get playing(): Boolean {
            return _isPlaying;
        }

        public function get paused(): Boolean {
            return _isPaused;
        }

        public function get ended(): Boolean {
            return _hasEnded;
        }

        public function get loadStarted(): Boolean {
            return _loadStarted;
        }

        public function get time(): Number {
            if (_model.duration > 0 &&
                hasActiveAdAsset &&
                _vpaidAd.hasOwnProperty("adRemainingTime") &&
                _vpaidAd.adRemainingTime >= 0 &&
                !isNaN(_vpaidAd.adRemainingTime)) {
                return _model.duration - _vpaidAd.adRemainingTime;
            } else {
                return 0;
            }
        }

        public function set src(pSrc:String): void {
            _src = pSrc;
			console("Set SRC!!!");
        }
        public function get src():String {
            return _src;
        }
		
		public function setSrcTest(pSrc:String):void {
			console("incoming src: " + pSrc);
			_src = pSrc;
			console("survey says... " + _src);
		}
		
		public function getSrc():String {
			return _src;
		}

        public function resize(width: Number, height: Number, viewMode: String = "normal"): void {
            if (hasActiveAdAsset) {
                _vpaidAd.resizeAd(width, height, viewMode);
            }
        }

        public function pausePlayingAd(): void {
            if (playing && !paused) {
                _isPlaying = true;
                _isPaused = true;
                _vpaidAd.pauseAd();
                _model.broadcastEventExternally(ExternalEventName.ON_PAUSE);
            }
        }

        public function resumePlayingAd(): void {
            if (playing && paused) {
                _isPlaying = true;
                _isPaused = false;
                _vpaidAd.resumeAd();
                _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
                
            }
        }

        public function startAd(): void {
            _vpaidAd.startAd();
        }
        
        private function onAdLoaded(): void {
            addChild(_vpaidAd);
            _model.broadcastEventExternally(VPAIDEvent.AdLoaded);
            SoundMixer.soundTransform = new SoundTransform(0);
        }

        private function onAdStarted(): void {
            //_model.broadcastEventExternally(ExternalEventName.ON_START)
            _model.broadcastEventExternally(VPAIDEvent.AdStarted);
            _isPlaying = true;
            _isPaused = false;
        }
        
        private function onAdError(): void {
            _model.broadcastErrorEventExternally(VPAIDEvent.AdError);
            _vpaidAd.stopAd();
        }
        
        private function onAdStopped(): void {
            if (!_hasEnded) {
                _isPlaying = false;
                _hasEnded = true;
                _vpaidAd = null;
                _model.broadcastEventExternally(VPAIDEvent.AdStopped);
                SoundMixer.soundTransform = new SoundTransform(0);
            }
            
        }
				
		public function findVPAIDSWF(xmlSrc:String):String {
			
			// create new XML from xmlSrc
			/*var vpaidXML = new XML(event.target.data);*/
			var vpaidXML = new XML(xmlSrc);
		  
			console("ad title test::" + vpaidXML.Ad.InLine.AdTitle.toString());
			console("ad vpaid version test::" + vpaidXML.attribute("version").toXMLString());
		
			// determine vpaid ad swf url within vpaidXML.Ad.InLine.Creatives
			var vpaidSWFURL:String = "";
			for each (var mediaFile:XML in vpaidXML.Ad.InLine.Creatives.Creative.Linear.MediaFiles.MediaFile) {
				console("MEDIA FILE");
				console(mediaFile.toString());
				if (mediaFile.toString().indexOf(".swf") != -1) {
					vpaidSWFURL = mediaFile;
				}
				
				/*var hasLinear:Boolean = (creative.Linear.children().length() > 0);
				if (hasLinear) {
					ExternalInterface.call("console.log", "CREATIVE!!!");
					ExternalInterface.call("console.log", creative.toXMLString());
					vpaidSWFURL = creative.Linear.MediaFiles[0].MediaFile.toString();
				}*/
			}


            if (vpaidXML.Ad.InLine.Creatives.Creative.Linear.AdParameters != "") {
               console("set adparameters");
               _model.adParameters = vpaidXML.Ad.InLine.Creatives.Creative.Linear.AdParameters

            }
		
			if (vpaidSWFURL != "") {
				/*console("ad swf found::" + vpaidSWFURL);*/
				return vpaidSWFURL;
			}
			else {
				/*console("no ad swf found, aborting?");*/
				return "error";
			}
		}
        
        public function loadAdAsset(): void {
			console("load ad asset: " + _src);
            _loadStarted = true;
            var loader:Loader = new Loader();
            var loaderContext:LoaderContext = new LoaderContext();
            loader.contentLoaderInfo.addEventListener(Event.INIT, function(evt) {
                    console("****** Load Ad Asset init: " + evt);
                    //successfulCreativeLoad(evt);
                });
            loader.contentLoaderInfo.addEventListener(ErrorEvent.ERROR, function (evt) {
                    console("******** Load Ad Asset Error: " + evt);
                });
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(evt:Object): void {
                console("****** Load Ad Asset Complete: " + evt);
                successfulCreativeLoad(evt);
            });
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, 
                function(evt:SecurityErrorEvent): void {
                    throw new Error(evt.text);
                });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, 
                function(evt:IOErrorEvent): void {
                    throw new Error(evt.text);
                });
            loader.load(new URLRequest(_src), loaderContext);
        }

        public function setDebug(pValue):void {
            _debug = pValue;
        }
        
        private function successfulCreativeLoad(evt: Object): void {

			console("successful creative load!");
            _vpaidAd = evt.target.content.getVPAID();
			/*console(_vpaidAd);*/
            var duration = _vpaidAd.hasOwnProperty("adDuration") ? _vpaidAd.adDuration : 0,
                width    = _vpaidAd.hasOwnProperty("adWidth") ? _vpaidAd.adWidth : 0,
                height   = _vpaidAd.hasOwnProperty("adHeight") ? _vpaidAd.adHeight : 0;

            if (!isNaN(duration) && duration > 0) {
                _model.duration = duration;
            }
            if (!isNaN(width) && width > 0) {
                _model.width = width;
            }
            if (!isNaN(height) && height > 0) {
                _model.height = height;
            }
			
			console("Duration: " + duration + " | Width: " + width + " | Height: " + height);

            _vpaidAd.addEventListener(VPAIDEvent.AdLoaded, function():void {
				console("OnAdLoaded");
                onAdLoaded();
            });
			
            _vpaidAd.addEventListener(VPAIDEvent.AdLog, function(data:*):void {
				console("OnAdLog");
                if (data) console(data);
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdStopped, function():void {
				console("OnAdStoppped");
                onAdStopped();
            });

            _vpaidAd.addEventListener(VPAIDEvent.AdImpression, function(evt):void {
                console("OnAdImpression: ");
                console(evt);
                _model.broadcastEventExternally(VPAIDEvent.AdImpression);
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdError, function(evt):void {
				console("OnVPAIDAdError: " + evt.data.message);
                console(evt);
                onAdError();
            });

            _vpaidAd.addEventListener(VPAIDEvent.AdSkipped, function():void {
                console("OnVPAIDAdSkipped: ");
            });

            _vpaidAd.addEventListener(VPAIDEvent.AdStarted, function():void {
				console("OnAdStarted");
                onAdStarted();
            });

            _vpaidAd.addEventListener(VPAIDEvent.AdVideoComplete, function():void {
                console("OnAdVideoComplete");
                _model.broadcastEventExternally(VPAIDEvent.AdVideoComplete);
            });

			console("handshake");
            _vpaidAd.handshakeVersion("2.0");

			console("initAd");
            // Use stage rect because current ad implementations do not currently provide width/height.
            _vpaidAd.initAd(_model.stageRect.width, _model.stageRect.height, "normal", _model.bitrate, _model.adParameters, _model.environmentVars);
        }
    }
}