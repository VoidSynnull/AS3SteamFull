package game.ar{
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Capabilities;
	import game.ar.as3.CameraUtils;
	import game.ar.as3.BitmapDataStats;
	import game.ar.examples.BRFBasicAS3Example;
	import game.ar.examples.face_tracking.png_mask_overlay;
	
	/**
	 * @author Marcel Klammer, Tastenkunst GmbH, 2017
	 */
	public class brfv4_ane_examples extends Sprite {
		
		public var _camUtils : CameraUtils;
		public var _stats : BitmapDataStats;
		public var _example : BRFBasicAS3Example;
		
		public var _width : Number = 640;
		public var _height : Number = 480;
		public var _isMobile : Boolean = false;
		
		public function brfv4_ane_examples() {
			
			if(stage == null) {
				addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			} else {
				onAddedToStage();
			}
		}
		
		private function onAddedToStage(event : Event = null) : void {
			
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.quality = StageQuality.MEDIUM;
			stage.frameRate = 30;
			
			init();
		}
		
		public function init() : void {
			
			var man : String		= Capabilities.manufacturer.toLowerCase();
			var iOS : Boolean		= man.indexOf("ios") >= 0;
			var android : Boolean	= man.indexOf("android") >= 0;
			var initialzedCamera : Boolean = false;
			
			_isMobile = iOS || android;
			_camUtils = new CameraUtils();
			_camUtils.addEventListener("ready", onCameraReady);
			
			if(iOS) {
				initialzedCamera = _camUtils.init(_width, _height, false, 90.0);
			} else if(android) {
				initialzedCamera = _camUtils.init(_width, _height, true, -90.0);
			} else { // desktop
				initialzedCamera = _camUtils.init(_width, _height, true,   0.0);
			}
			
			if(!initialzedCamera) {
				trace("No camera found.");
			}
		}
		
		private function onCameraReady(event : Event = null) : void {
			
			// Choose only one of the following examples:
			
			// "+++ basic - face detection +++"
			
			//			_example = new detect_in_whole_image();					// "basic - face detection - detect in whole image"
			//			_example = new detect_in_center();						// "basic - face detection - detect in center"
			//			_example = new detect_smaller_faces();					// "basic - face detection - detect smaller faces"
			//			_example = new detect_larger_faces();					// "basic - face detection - detect larger faces"
			//
			// "+++ basic - face tracking +++"
			
			//			_example = new track_single_face();						// "basic - face tracking - track single face"
			//			_example = new track_multiple_faces();					// "basic - face tracking - track multiple faces"
			//			_example = new candide_overlay();						// "basic - face tracking - candide overlay"
			
			// "+++ basic - point tracking +++"
			
			//			_example = new track_multiple_points();					// "basic - point tracking - track multiple points"
			//			_example = new track_points_and_face();					// "basic - point tracking - track points and face"
			
			// "+++ intermediate - face tracking +++"
			
			//			_example = new restrict_to_center();					// "intermediate - face tracking - restrict to center"
			//			_example = new extended_face_shape();					// "intermediate - face tracking - extended face"
			//			_example = new smile_detection();						// "intermediate - face tracking - smile detection"
			//			_example = new yawn_detection();						// "intermediate - face tracking - yawn detection"
			_example = new png_mask_overlay();						// "intermediate - face tracking - png/mask overlay"// i think this example most closely represents what we will be using
			//			_example = new color_libs();							// "intermediate - face tracking - color libs"
			
			// "+++ advanced - face tracking +++"
			
			//			_example = new blink_detection();						// "advanced - face tracking - blink detection"
			//			_example = new Flare3d_example();						// "advanced - face tracking - Flare3D example"
			//			_example = new face_texture_overlay();					// "advanced - face tracking - face texture overlay"
			//			_example = new face_swap_two_faces();					// "advanced - face tracking - face swap (two faces)"
			
			_stats = new BitmapDataStats();
			
			addChild(_camUtils.video);//include camera feed
			/*
			if(!(_example is Flare3d_example)) {
			addChild(_camUtils.video);	
			}
			*/
			addChild(_example);
			addChild(_stats);
			
			_example.initCurrentExample(_example.brfManager, _camUtils.cameraResolution);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		public function onEnterFrame(event : Event = null) : void {
			
			_camUtils.update();
			
			_example.updateCurrentExample(
				_example.brfManager, 
				_camUtils.cameraData, 
				_example.drawing
			);
		}
		
		public function onResize(event : Event = null) : void {
			
			var w : Number = _width;
			var h : Number = _height;
			
			if(_isMobile) { // portrait
				w = _height;
				h = _width;
			}
			
			scaleX = stage.stageWidth / w;
			scaleY = scaleX;
			y = (stage.stageHeight - (h * scaleY)) * 0.5;
		}
	}
}