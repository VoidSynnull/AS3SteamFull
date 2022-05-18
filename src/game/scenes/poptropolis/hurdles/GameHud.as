package game.scenes.poptropolis.hurdles
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.group.UIView;
	
	import game.creators.ui.ButtonCreator;
	
	import org.osflash.signals.Signal;
	
	public class GameHud extends UIView
	{
		public var exitClicked:Signal
		public var stopRaceClicked:Signal
		public var startGunFire:Signal
		
		private var _exitBtn:Entity;
		private var _stopRaceBtn:Entity;
		private var _countClip:Entity;
		
		private var _startTimer:Timer;
		private var _secondsToStart:int;
		
		public function GameHud(container:DisplayObjectContainer=null)
		{
			super(container);
			super.id = "gameHud";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "scenes/poptropolis/hurdles/";
			
			// Create this groups container.
			super.init(container);
			
			// load this groups assets.
			load();
			
			exitClicked = new Signal()
			stopRaceClicked = new Signal()
			startGunFire = new Signal()
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// do the asset load, and listen for the 'assetLoadComplete' to do setup.
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("hud.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			// get the screen movieclip from the loaded assets.
			super.screen = super.getAsset("hud.swf", true) as MovieClip;
			super.groupContainer.addChild(super.screen);
			
			var clip:MovieClip
			var interaction:Interaction
			
			clip = MovieClip(super.screen.btnExitPractice);
			_exitBtn = ButtonCreator.createButtonEntity(clip, this);
			interaction = Interaction(_exitBtn.get(Interaction));
			interaction.upNative.add( onExitBtnUp );
			
			clip = MovieClip(super.screen.btnStopRace);
			_stopRaceBtn = ButtonCreator.createButtonEntity(clip, this);
			interaction = Interaction(_stopRaceBtn.get(Interaction));
			interaction.upNative.add( onStopRaceBtnUp );
			
			clip = MovieClip(super.screen.mcCountdown)
			_countClip = new Entity()
			_countClip.add(new Display(clip))
			setCountdownText ("")
			
			// Call the parent classes loaded() method so it knows this Group is ready.
			super.loaded();
		}
		
		private function setCountdownText(s:String):void
		{
			_countClip.get(Display).displayObject.tf.text = s
		}
		
		private function onStopRaceBtnUp (e:Event):void {
			//trace ("[GameHud] -------------onStopRaceBtnUp")
			exitClicked.dispatch();
		}
		
		private function onExitBtnUp (e:Event):void {
			stopRaceClicked.dispatch();
		}
		
		public function setMode (s:String):void {
			switch (s) {
				case "race":
					super.screen.btnExitPractice.visible = false
					super.screen.btnStopRace.visible = true
					break
				case "practice":
					super.screen.btnExitPractice.visible = true
					super.screen.btnStopRace.visible = false
					break
				case "clear":
					super.screen.btnExitPractice.visible = false
					super.screen.btnStopRace.visible = false
					break
			}
		}
		
		public function startCountdown ():void {
			_secondsToStart = 3
			setCountdownText(String(_secondsToStart))
			_startTimer = new Timer(700,_secondsToStart)
			_startTimer.addEventListener(TimerEvent.TIMER,onCountdownTimer)
			_startTimer.start()
		}
		
		
		private function onCountdownTimer (e:Event):void {
			
			_secondsToStart --
			if (_secondsToStart ==0 ) {
				startGunFire.dispatch()
				setCountdownText("")
			}
			else {
				setCountdownText(String(_secondsToStart))
			}
		}
		
	}
}


