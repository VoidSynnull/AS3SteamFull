package game.scenes.poptropolis.skiing
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.UIView;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ButtonCreator;
	import game.util.AudioUtils;
	
	import org.osflash.signals.Signal;
	
	public class SkiingHud extends UIView
	{
		public var exitClicked:Signal
		public var stopRaceClicked:Signal
		public var startGunFire:Signal
		
		private var _exitBtn:Entity;
		private var _stopRaceBtn:Entity;
		private var _countDownEntity:Entity;
		private var _timer:Timer;
		private var _secondsToStart:int;
		private var timerTick:Signal;
		private var _raceTimerEntity:Entity;
		private var _startTime:int;
		
		private var _elapsedMilliseconds:Number;
		
		private var _timeBonus:Entity;
		
		public function SkiingHud(container:DisplayObjectContainer=null)
		{
			super(container);
			super.id = "gameHud";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "scenes/poptropolis/skiing/";
			
			// Create this groups container.
			super.init(container);
			
			// load this groups assets.
			load();
			
			exitClicked = new Signal()
			stopRaceClicked = new Signal()
			startGunFire = new Signal()
			
			timerTick = new Signal()
			
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
			_countDownEntity = new Entity()
			_countDownEntity.add(new Display(clip))
			setCountdownText ("")
			
			clip = MovieClip(super.screen.mcTimer)
			_raceTimerEntity = new Entity()
			_raceTimerEntity.add(new Display(clip))
			
			clip = MovieClip(super.screen.mcTimeBonus)
			_timeBonus = new Entity()
			_timeBonus.add(new Display(clip))
			_timeBonus.add(new Spatial)
			_timeBonus.add(new Motion)
			this.addEntity(_timeBonus)
			if (_timeBonus.get(Display).displayObject.tf) _timeBonus.get(Display).displayObject.tf.text = String (-Skiing.GATE_BONUS_SECONDS)
			
			// Call the parent classes loaded() method so it knows this Group is ready.
			super.loaded();
		}
		
		public function startRaceTimer():void{
			_timer = new Timer(100)
			_timer.addEventListener(TimerEvent.TIMER,onTimer)
			_timer.start()
			_startTime = getTimer()
			resetRaceTimer()
		}
		
		private function onTimer (e:Event):void {
			_elapsedMilliseconds = getTimer() - _startTime
			drawRaceTimer()
		}
		
		private function drawRaceTimer():void
		{
			var minutes:int = Math.floor (_elapsedMilliseconds/1000/60) 
			var seconds:int = Math.floor (_elapsedMilliseconds/1000)
			seconds = seconds % 60
			var decSeconds:int = Math.floor (_elapsedMilliseconds/100) % 10
			
			var mStr:String = String (minutes) + ":" 
			var sStr:String = (seconds < 10) ? "0" + String (seconds) : String (seconds)
			_raceTimerEntity.get(Display).displayObject.tf.text = mStr + sStr + ":" + decSeconds// + "0"			
		}
		
		public function showTimeBonus (__player:Entity):void {
			onTimeBonusReachedTimer()
			return
			var ts:Spatial = _timeBonus.get(Spatial) as Spatial
			var dp:DisplayObject = Display(__player.get(Display)).displayObject
			var tp:DisplayObject = Display(_timeBonus.get(Display)).displayObject
			tp.parent.addChild(tp)
			ts.x = dp.x
			ts.y = dp.y-100
			
			var t:Tween = new Tween()
			_timeBonus.add(t)
			t.to(ts, .75, { x: 128, y: 517, ease:Sine.easeInOut, onComplete: onTimeBonusReachedTimer})
		}
		
		private function onTimeBonusReachedTimer ():void {
			var dp:MovieClip  = MovieClip( Display(_raceTimerEntity.get(Display)).displayObject)
			dp.gotoAndPlay("bonus")
			var ts:Spatial = _timeBonus.get(Spatial) as Spatial
			ts.x = -500
			_startTime += Skiing.GATE_BONUS_SECONDS	* 1000
		}
		
		public function showTimePenalty ():void {
			var dp:MovieClip  = MovieClip( Display(_raceTimerEntity.get(Display)).displayObject)
			dp.gotoAndPlay("penalty")
			var ts:Spatial = _timeBonus.get(Spatial) as Spatial
			ts.x = -500
			_startTime += Skiing.GATE_BONUS_SECONDS	* 1000
		}
		
		public function get raceTime ():Number {
			return	Math.floor(_elapsedMilliseconds/100) / 10
		}
		
		public function stopRaceTimer():void
		{
			_timer.stop()
		}
		
		private function setCountdownText(s:String):void
		{
			_countDownEntity.get(Display).displayObject.tf.text = s
		}
		
		private function onStopRaceBtnUp (e:Event):void {
			//trace ("[GameHud] -------------onStopRaceBtnUp")
			stopRaceClicked.dispatch();
		}
		
		private function onExitBtnUp (e:Event):void {
			exitClicked.dispatch();
		}
		
		public function setMode (s:String):void {
			trace ("[SkiingHud] setMode:" + s)
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
			(_stopRaceBtn.get(Display) as Display).visible = false
		}
		
		public function startCountdown ():void {
			_secondsToStart = 3
			setCountdownText(String(_secondsToStart))
			_timer = new Timer(700,_secondsToStart)
			_timer.addEventListener(TimerEvent.TIMER,onCountdownTimer)
			_timer.start()
			_countDownEntity.get(Display).displayObject.visible = true
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "countdown_01" +".mp3");
		}
		
		private function onCountdownTimer (e:Event):void {
			
			_secondsToStart --
			if (_secondsToStart ==0 ) {
				startGunFire.dispatch()
				setCountdownText("")
				_countDownEntity.get(Display).displayObject.visible = false
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "countdown_02" +".mp3");
			}
			else {
				setCountdownText(String(_secondsToStart))
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "countdown_01" +".mp3");
			}
		}
		
		private function setVisibleFalse (mc:MovieClip):void {
			mc.visible = false
		}
		
		public function abortRace():void
		{
			stopRaceTimer()
		}
		
		public function resetRaceTimer():void
		{
			_elapsedMilliseconds = 0
			drawRaceTimer()	
		}
	}
}


