package game.scenes.poptropolis.common
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import avmplus.getQualifiedClassName;
	
	import engine.components.Interaction;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	import org.osflash.signals.Signal;
	
	public class PoptropolisInstructions extends Popup
	{
		public var startClicked:Signal
		public var practiceClicked:Signal
		public var debugClicked:Signal
		
		private var _scene:String;
		
		public function PoptropolisInstructions(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			startClicked = new Signal( );
			practiceClicked = new Signal( );
			debugClicked = new Signal( );
			
			var className:String = getQualifiedClassName(parent)
			if (className.indexOf ("::") != -1) className = className.split ("::")[0];
			var arr:Array = className.split(".")
			_scene = arr[arr.length-1]
			super.groupPrefix = "scenes/poptropolis/" + _scene + "/";
			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.transitionOut.duration = .2;
			
			super.darkenBackground = true;
			super.init(container);

			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.loadFiles([_scene + "Instructions.swf"], false, true, loaded);
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.screen = super.getAsset(_scene + "Instructions.swf", true) as MovieClip;
			
			super.layout.centerUI(super.screen.content);
		
			var clip:MovieClip = MovieClip(super.screen.content.btnStart);
			var _startBtn:Entity = ButtonCreator.createButtonEntity(clip, this, onStartBtnUp);
			
			clip = MovieClip(super.screen.content.btnPractice);
			var _practiceBtn:Entity = ButtonCreator.createButtonEntity(clip, this, onPracticeBtnUp);
			
			clip = MovieClip(super.screen.content.btnDebug);
			if (clip) {
				var _debugBtn:Entity = ButtonCreator.createButtonEntity(clip, this, onDebugBtnUp);
			}
			
			if (screen.content.mcPages) {
				//	trace ("[PoptropolisInstructions] mcPages!")
				screen.content.mcPages.btnBack.addEventListener (MouseEvent.CLICK, onPageBackClick)
				screen.content.mcPages.btnNext.addEventListener (MouseEvent.CLICK, onPageNextClick)
				checkPageBtns()
			}
			
			super.loaded();
		}
		
		private function onPageBackClick (e:Event): void {
			var f:int = screen.content.mcPages.currentFrame - 1
			if (f > 0) {
				screen.content.mcPages.gotoAndStop(f)
				checkPageBtns()
			}
		}
		
		private function onPageNextClick (e:Event): void {
			var f:int = screen.content.mcPages.currentFrame + 1
			if (f <= screen.content.mcPages.totalFrames) {
				screen.content.mcPages.gotoAndStop(f)
				checkPageBtns()
			}
		}
		
		private function checkPageBtns():void
		{
			screen.content.mcPages.btnBack.alpha = screen.content.mcPages.currentFrame > 1 ? 1 : .5
			screen.content.mcPages.btnNext.alpha = screen.content.mcPages.currentFrame < screen.content.mcPages.totalFrames ? 1 : .5
		}
		
		private function onStartBtnUp ( entity:Entity = null ):void 
		{
			startClicked.dispatch();
			super.close();
		}
		
		private function onPracticeBtnUp ( entity:Entity = null ):void 
		{
			practiceClicked.dispatch();
			super.close();
		}
		
		private function onDebugBtnUp ( entity:Entity = null ):void 
		{
			debugClicked.dispatch();
			super.close();
		}
		
	}
}
