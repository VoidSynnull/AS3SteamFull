package game.scenes.poptropolis.longJump
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.UIView;
	
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class LongJumpHud extends UIView
	{
		private var _attemptNumEntity:Entity
		private var _attemptNum:Number;
		private var _exitBtn:Entity;
		
		public var resultDisplayComplete:Signal
		public var exitPracticeClicked:Signal
		
		private var _resultEntity:Entity;
		private var _foulEntity:Entity;
		
		public function LongJumpHud(container:DisplayObjectContainer=null)
		{
			super(container);
			super.id = "gameHud";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "scenes/poptropolis/longJump/";
			
			// Create this groups container.
			super.init(container);
			
			// load this groups assets.
			load();
			
			resultDisplayComplete = new Signal()
			exitPracticeClicked = new Signal()
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// do the asset load, and listen for the 'assetLoadComplete' to do setup.
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("longJumpHud.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			// get the screen movieclip from the loaded assets.
			super.screen = super.getAsset("longJumpHud.swf", true) as MovieClip;
			super.groupContainer.addChild(super.screen);
			
			var interaction:Interaction
			
			_attemptNumEntity = EntityUtils.createSpatialEntity(this,  MovieClip(super.screen.mcAttemptNum));
			_attemptNumEntity.get(Display).visible = false
			
			_resultEntity = EntityUtils.createSpatialEntity(this,  MovieClip(super.screen.mcResult));
			(_resultEntity.get(Display) as Display).visible = false
			
			_foulEntity = EntityUtils.createSpatialEntity(this,  MovieClip(screen.mcFoul));
			(_foulEntity.get(Display) as Display).visible = false
			
			var mc:MovieClip = MovieClip(super.screen.btnExitPractice);
			_exitBtn = ButtonCreator.createButtonEntity(mc, this);
			interaction = Interaction(_exitBtn.get(Interaction));
			interaction.upNative.add( onExitBtnUp );
			super.loaded();
		}
		
		private function onExitBtnUp (e:Event):void {
			exitPracticeClicked.dispatch();
		}
		
		public function setAttemptNum(n:Number):void
		{
			_attemptNum = n
			var d:Display = Display (_attemptNumEntity.get(Display))
			var mc:MovieClip = MovieClip (d.displayObject)
			Display(_attemptNumEntity.get(Display)).visible = true
			Display(_attemptNumEntity.get(Display)).alpha = 0
			_attemptNumEntity.get(Spatial).scaleX = _attemptNumEntity.get(Spatial).scaleY = .5
			mc.gotoAndStop (n)
			animateInEntity(_attemptNumEntity)
			SceneUtil.addTimedEvent( this, new TimedEvent(2, 1, hideAttemptNum));
		}
		
		private function hideAttemptNum ():void {
			hideAnimateEntity(_attemptNumEntity)
		}
		
		public function showResult (n:Number,best:Number, firstJump:Boolean):void {
			var a:Array = ["dummy","First Attempt:", "Second Attempt:", "Final Attempt:"]
			var d:Display = Display (_resultEntity.get(Display))
			var mc:MovieClip = MovieClip (d.displayObject)
			mc.tfHeader.text = a[_attemptNum]
			mc.tfDistance.text = String (n) + " Meters!"
			mc.tfBest.text = "Your farthest distance:" + best + " Meters"
			animateInEntity (_resultEntity)
			SceneUtil.addTimedEvent( this, new TimedEvent(3, 1, hideResults));
		}
		
		public function showPracticeResult(score:Number):void
		{
			var d:Display = Display (_resultEntity.get(Display))
			var mc:MovieClip = MovieClip (d.displayObject)
			mc.tfDistance.text = String (score) + " Meters"
			mc.tfBest.text = "practice jump"
			animateInEntity(_resultEntity)
			SceneUtil.addTimedEvent( this, new TimedEvent(2, 1, hideResults));
		}
		
		private function hideResults():void
		{
			dispatchResultsDone()	
			hideAnimateEntity(_resultEntity)
		}
		
		private function animateInEntity (entity:Entity, secsOnScreen:Number=4):void 
		{
			var tween:Tween = new Tween();
			entity.add(tween)
			var display:Display = entity.get(Display);
			display.visible = true;
			display.alpha = 1
			var spatial:Spatial = entity.get(Spatial)
			spatial.scaleX = spatial.scaleY = .5
			tween.to(spatial,.6, {scaleX:1.4, scaleY:1.4,ease:Sine, onComplete:animateInEntity2 , onCompleteParams:[entity]})
		}
		
		private function animateInEntity2 (entity:Entity):void 
		{
			var spatial:Spatial = entity.get (Spatial)
			entity.get(Tween).to(spatial,.7, {scaleX:1, scaleY:1,ease:Sine, onComplete:animateInEntity3, onCompleteParams:[entity]})
		}
		
		private function animateInEntity3 (entity:Entity):void 
		{
			var display:Display = entity.get(Display);
			entity.get(Tween).to( display, .5, { alpha:1})
		}
		
		private function hideAnimateEntity (entity:Entity):void
		{
			entity.get(Tween).to(entity.get(Spatial),.2, {scaleX:1.3, scaleY:1.3,ease:Sine,onComplete:hideAnimateEntity2,onCompleteParams:[entity]})
		}
		
		private function hideAnimateEntity2 (entity:Entity):void 
		{
			entity.get(Tween).to(entity.get(Spatial),.6, {scaleX:.1, scaleY:.1,ease:Sine})
			entity.get(Tween).to(entity.get(Display), .6, {alpha:0})
		}
		
		private function dispatchResultsDone ():void {
			resultDisplayComplete.dispatch()
		}
		
		public function showFoul ():void {
			animateInEntity(_foulEntity )
			SceneUtil.addTimedEvent( this, new TimedEvent(1.5, 1, hideFoul));
		}
		
		private function hideFoul ():void {
			hideAnimateEntity(_foulEntity)
		}
		
		public function setMode (s:String):void {
			switch (s) {
				case "race":
					(_exitBtn.get(Display) as Display).visible = false;
					break
				case "practice":
					(_exitBtn.get(Display) as Display).visible = true
					break
				case "clear":
					(_exitBtn.get(Display) as Display).visible  = false
					break
			}
			super.screen.btnStopRace.visible = false
		}
		
		public function clear():void
		{
			(_foulEntity.get(Display) as Display).visible = false;
			(_resultEntity.get(Display) as Display).visible = false
			_attemptNumEntity.get(Display).visible = false
		}
	}
}



