package game.scenes.lands.shared.systems {
	
	/**
	 *
	 * A system for keeping track of the "Start" "Finish" race tiles
	 * 
	 *
	 */
	
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	import ash.core.Engine;
	import ash.core.System;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.popups.racePopup.RacePopup;
	
	public class RaceSystem extends System {

		private var landGroup:LandGroup;
		private var raceTimer:MovieClip;
		private var timeTxt:TextField;
		
		//timer vars
		//private var startTime:Date;
		private var timer:Timer;
		private var totalSeconds:int = 0;
		
		public function RaceSystem() {
			
			super();
			
		} //

		public function get currentTime():int {

			// basically the number of seconds the timer has been running.
			return this.totalSeconds;

		}
		public function set currentTime( seconds:int ):void {

			this.totalSeconds = seconds;
			if ( this.timeTxt != null ) {
				this.timeTxt.text = this.totalSeconds.toString();
			}

		} //

		public function get isRunning():Boolean {
			return this.timer.running;
		}

		// not using.
		/*override public function update( time:Number ):void {
		} // update();*/

		override public function addToEngine( systemManager:Engine ):void {

			this.landGroup = LandGroup( this.group );
			this.landGroup.shellApi.loadFile( this.landGroup.sharedAssetURL + "race_timer.swf", this.assetsLoaded );

		} //

		private function assetsLoaded( clip:MovieClip ):void {

			this.raceTimer = clip;
			this.raceTimer.mouseEnabled = this.raceTimer.mouseChildren = false;
			
			this.landGroup.curScene.overlayContainer.addChildAt( this.raceTimer, 0 );
			this.raceTimer.y = 72;
			this.raceTimer.x = 127;
			
			this.timeTxt = this.raceTimer["timeTxt"];
			this.timeTxt.text = this.totalSeconds.toString();

			this.timer = new Timer( 1000, 0 );
			this.timer.addEventListener(TimerEvent.TIMER, onTickTimer);
			this.timer.start();

		} //

		private function onTickTimer(e:TimerEvent):void {

			this.totalSeconds++;
			this.timeTxt.text = String( this.totalSeconds );

		}
		
		public function finishRace():void {

			//trace("RACE FINISHED");
			this.stopTimer();

			var racePopup:RacePopup = new RacePopup(totalSeconds, this.landGroup.curScene.overlayContainer);
			this.landGroup.curScene.addChildGroup(racePopup);
			this.group.removeSystem( this );

		} //

		public function stopTimer():void {

			timer.stop();
			timer.removeEventListener( TimerEvent.TIMER, this.onTickTimer );
			timer = null;

			if ( this.raceTimer && this.raceTimer.parent ) {
				this.raceTimer.parent.removeChild( this.raceTimer );
			} //

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			// this is necessary in case the timer is running when the player leaves the scene.
			if ( timer && timer.running ) {

				this.stopTimer();

			} //

			//this.colliderNodes = null;
			//this.specialNodes = null;
			
		} //
		
	} // End class
	
} // End package