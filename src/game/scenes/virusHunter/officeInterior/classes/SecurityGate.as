package game.scenes.virusHunter.officeInterior.classes {

	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.group.Scene;
	import engine.managers.SoundManager;
	
	import game.scenes.virusHunter.condoInterior.classes.UpdateManager;
	import game.util.AudioUtils;

	public class SecurityGate {

		static private const Y_MIN:Number = 208;
		static private const OPEN_DOOR:String = "door_gate_open_01.mp3";
		static private const AIRLOCK:String = "door_airlock_close_01.mp3";
		static private const ACCESS_GRANTED:String = "green_light_01.mp3";
			
		static public const OPEN:int = 1;
		static public const CLOSED:int = 2;
		static public const OPENING:int = 3;
		static public const CLOSING:int = 4;

		private var Y_MAX:Number;

		private var door:MovieClip;
		private var barrier:MovieClip;

		private var wallHit:Entity;

		private var goalY:Number;

		public var curState:int;

		public var onDoorOpened:Function;
		public var onDoorClosed:Function;

		private var updater:UpdateManager;
		private var scene:Scene;

		public function SecurityGate( door:MovieClip, updater:UpdateManager, scene:Scene ) {

			this.door = door;
			this.barrier = door.barrier;

			this.updater = updater;
			this.scene = scene;
			curState = CLOSED;
			Y_MAX = barrier.y;

		} //

		public function update( time:Number ):void {

			barrier.y += 4*( goalY - barrier.y )*time;

			if ( Math.abs( goalY - barrier.y ) <= 2 ) {

				barrier.y = goalY;

				updater.removeUpdate( this.update );

				moveDone();

			} // end-if.

		} //

		public function doOpen( callback:Function=null ):void {

			if ( callback != null ) {
				onDoorOpened = callback;
			} //

			if ( curState == OPENING ) {
				return;
			}

			goalY = Y_MIN;
			curState = OPENING;
			//scene.shellApi.soundManager.play( SoundManager.EFFECTS_PATH + OPEN_DOOR );
			//scene.shellApi.soundManager.play( SoundManager.EFFECTS_PATH + ACCESS_GRANTED );
			AudioUtils.play(scene, SoundManager.EFFECTS_PATH + OPEN_DOOR);
			AudioUtils.play(scene, SoundManager.EFFECTS_PATH + ACCESS_GRANTED);
			// set onEnterFrame
			updater.addUpdate( update );

		} //

		public function doClose( callback:Function=null ):void {

			if ( callback != null ) {
				onDoorClosed = callback;
			} //

			if ( curState == CLOSING ) {
				return;
			}

			goalY = Y_MAX;
			curState = CLOSING;
			//scene.shellApi.soundManager.play( SoundManager.EFFECTS_PATH + AIRLOCK );
			AudioUtils.play(scene, SoundManager.EFFECTS_PATH + AIRLOCK);
			// set onEnterFrame
			updater.addUpdate( update );

		} //

		private function moveDone():void {

			if ( curState == OPENING ) {

				curState = OPEN;
				if ( onDoorOpened != null ) {
					onDoorOpened( this );
				}

			} else if ( curState == CLOSING ) {

				curState = CLOSED;
				if ( onDoorClosed != null ) {
					onDoorClosed( this );
				}

			} //

		} //

	} // End SecurityDoor
	
} // End package