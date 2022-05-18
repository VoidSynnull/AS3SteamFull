package game.scenes.carnival.ridesNight {

	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.scenes.carnival.shared.ferrisWheel.FerrisWheelGroup;
	import game.scenes.carnival.shared.ferrisWheel.components.StickToEntity;
	import game.scenes.virusHunter.condoInterior.components.SimpleUpdater;
	import game.scenes.virusHunter.condoInterior.systems.SimpleUpdateSystem;
	import game.systems.SystemPriorities;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;

	public class ImpGroup extends Group {

		/**
		 * Strings for the timeline animation frames. I'm not sure when they're all suppose to be used, really.
		 */
		public const FAST_BEGIN:String = "fast_begin";					// used when ride is going fast.
		public const FAST_END:String = "fast_end";						// loop marker
		public const RIDE_SLOWS_BEGIN:String = "ride_slows_begin";		// used when ride is slowed by gum.
		public const RIDE_SLOWS_END:String = "ride_slows_end";			// end marker.

		public const SLOW_BEGIN:String = "slow_begin";					// used when ride is going slowly.
		public const SLOW_END:String = "slow_end";						// loop marker.

		public const DUCK_BEGIN:String = "duck_begin";
		public const DUCK_END:String = "duck_end";

		public const POPUP_BEGIN:String = "popup_begin";
		public const POPUP_END:String = "popup_end";
		public const PEEKING_BEGIN:String = "peeking_begin";
		public const PEEKING_END:String = "peeking_end";
		public const POPDOWN_BEGIN:String = "popdown_begin";
		public const POPDOWN_END:String = "popdown_end";

		public const FALLING_BEGIN:String = "falling_begin";
		public const FALLING_END:String = "falling_end";

		public const HIT_BEGIN:String = "hit_begin";					// hit begin doesnt need an end marker because it runs straight through to ground_begin.
		public const GROUND_BEGIN:String = "ground_begin";
		public const GROUND_END:String = "ground_end";


		/**
		 * Some basic states needed to check that animation switches don't happen incorrectly.
		 */
		private const RIDING_STATE:int = 1;			// normal ride mode, fast or slow.
		private const DUCKING_STATE:int = 2;			// already ducking.
		private const PEEKING_STATE:int = 3;			// peeking up after duck
		private const POPPING_STATE:int = 4;			// popping up or down.

		private var curState:int;

		private var cars:Vector.<Entity>;

		private var imp:Entity;
		private var impTimeline:Timeline;			// Current imp timeline. need this due to alot of animations.
		private var impSpatial:Spatial;

		private var curFerrisIndex:int = 0;

		private var ferrisGroup:FerrisWheelGroup;

		private var hitContainer:MovieClip;

		public var onHitGround:Signal;		// gives entity of the imp that actually hit.

		private var groundY:Number = 1700;

		private var player:Entity;
		private var pSpatial:Spatial;		// player spatial.

		public function ImpGroup() {

			super();

			this.onHitGround = new Signal( Entity );

		}

		public function init( impClip:MovieClip ):void {

			this.ferrisGroup = this.parent.getGroupById( "ferrisGroup" ) as FerrisWheelGroup;
			this.hitContainer = impClip;

			this.player = this.parent.getEntityById( "player" );
			this.pSpatial = this.player.get( Spatial );

			//this.addSystem( new StickToEntitySystem(), SystemPriorities.postUpdate );
			this.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );

			this.createImp();

			if ( this.ferrisGroup.getRotationVelocity() > 25 ) {
				this.impTimeline.gotoAndPlay( this.FAST_BEGIN );
			} else {
				this.impTimeline.gotoAndPlay( this.SLOW_BEGIN );
			} // end-if.

			this.curState = this.RIDING_STATE;

		} //

		private function createImp():void {

			this.cars = this.ferrisGroup.getSwings();

			var mc:MovieClip = this.hitContainer[ "imp" ];
			this.hitContainer.setChildIndex( mc, mc.parent.numChildren-1 );

			var e:Entity = this.imp = TimelineUtils.convertClip( mc, this, null, null, false );
			this.impTimeline = e.get( Timeline ) as Timeline;
			this.impTimeline.labelReached.add( this.onLabel );

			var carSpatial:Spatial = this.cars[0].get( Spatial ) as Spatial;			// spatial of the car/swing being ridden by imp

			this.impSpatial = new Spatial( mc.x, mc.y );

			e.add( new Display( mc ), Display );
			e.add( this.impSpatial, Spatial );
			e.add( new Sleep( false, true ), Sleep );
			e.add( new StickToEntity( this.cars[0], mc.x - carSpatial.x, mc.y - carSpatial.y ), StickToEntity );
			e.add( new SimpleUpdater( this.checkPlayer ), SimpleUpdater );

			this.curFerrisIndex = 0;

		} //

		/**
		 * Check distance between player and imp and change imp cars if the player is too close.
		 */
		private function checkPlayer( time:Number ):void {

			if ( this.curState != this.RIDING_STATE && this.curState != this.PEEKING_STATE ) {
				// imp can only ducking out when riding or peeking. Not when already ducking/popping.
				return;
			}

			if ( Math.abs( this.pSpatial.x - this.impSpatial.x ) > 100 ) {
				return;
			}

			if ( Math.abs( this.pSpatial.y - this.impSpatial.y ) > 144 ) {
				return;
			}

			if ( this.curState == this.RIDING_STATE ) {
				this.impTimeline.gotoAndPlay( this.DUCK_BEGIN );
				this.curState = this.DUCKING_STATE;
			} else if ( this.curState == this.PEEKING_STATE ) {
				this.impTimeline.gotoAndPlay( this.POPDOWN_BEGIN );
				this.curState = this.POPPING_STATE;
			}

		} //

		public function dropImp( onGroundHit:Function=null, baseGround:Number=1758 ):void {

			this.impTimeline.gotoAndPlay( this.FALLING_BEGIN );

			var motion:Motion = new Motion();

			motion.velocity.y = -50;
			motion.acceleration.y = 800;

			this.imp.add( motion, Motion );
			this.imp.remove( StickToEntity );

			var updater:SimpleUpdater = this.imp.get( SimpleUpdater );
			updater.update = this.checkHitGround;

			if ( onGroundHit ) {
				this.onHitGround.addOnce( onGroundHit );
			}

			this.groundY = baseGround - 30;

		} //

		private function checkHitGround( time:Number ):void {

			var spatial:Spatial = this.imp.get( Spatial );

			if ( spatial.y > this.groundY ) {

				this.imp.remove( SimpleUpdater );
				this.imp.remove( Motion );

				this.removeSystemByClass( SimpleUpdateSystem, true );
				this.impTimeline.gotoAndPlay( this.HIT_BEGIN );

			} //

		} //

		private function onLabel( label:String ):void {

			// First check basic loops.
			if ( label == this.FAST_END ) {
				this.impTimeline.gotoAndPlay( this.FAST_BEGIN );
			} else if ( label == this.SLOW_END ) {
				this.impTimeline.gotoAndPlay( this.SLOW_BEGIN );
			} else if ( label == this.FALLING_END ) {
				this.impTimeline.gotoAndPlay( this.FALLING_BEGIN );
			} else if ( label == this.PEEKING_END ) {
				this.impTimeline.gotoAndPlay( this.POPDOWN_BEGIN );
			}

			else if ( label == this.DUCK_END ) {

				this.impTimeline.gotoAndPlay( this.POPUP_BEGIN );
				this.curState = this.POPPING_STATE;
				// swap to an adjacent car.
				this.changeCars();

			} else if ( label == this.POPDOWN_END ) {

				this.impTimeline.gotoAndPlay( this.POPUP_BEGIN );
				this.curState = this.POPPING_STATE;
				// swap to an adjacent car.
				this.changeCars();

			}

			else if ( label == this.POPUP_END ) {
				this.impTimeline.gotoAndPlay( this.PEEKING_BEGIN );
				this.curState = this.PEEKING_STATE;
			}

			else if ( label == this.RIDE_SLOWS_END ) {
				this.impTimeline.gotoAndPlay( this.SLOW_BEGIN );			// ride has slowed. go into the basic slow-idle loop.
			}

			else if ( label == this.GROUND_END ) {

				// hit ground. everything done.
				this.impTimeline.stop();				// for some reason, this alone won't stop the timeline.
				this.impTimeline.lock = true;
				this.onHitGround.dispatch( this.imp );

			} //

		} //

		public function changeCars():void {

			if ( Math.random() < 0.5 ) {

				if ( --this.curFerrisIndex < 0 ) {
					this.curFerrisIndex = this.cars.length-1;
				}

			} else {
				this.curFerrisIndex = ( this.curFerrisIndex + 1 ) % this.cars.length;
			} // end-if.

			var stick:StickToEntity = this.imp.get( StickToEntity );
			stick.entity = this.cars[ this.curFerrisIndex ];
			stick.entitySpatial = this.cars[ this.curFerrisIndex ].get( Spatial );

		} //

		public function slowDown():void {

			this.impTimeline.gotoAndPlay( this.RIDE_SLOWS_BEGIN );
			this.curState = this.RIDING_STATE;

		} //

		public function popdownImp():void {

			this.impTimeline.gotoAndPlay( this.POPDOWN_BEGIN );
			this.curState = this.POPPING_STATE;

		} //

		public function popupImp():void {

			this.impTimeline.gotoAndPlay( this.POPUP_BEGIN );
			this.curState = this.POPPING_STATE;

		} //

		public function duckImp():void {

			this.impTimeline.gotoAndPlay( this.DUCK_BEGIN );
			this.curState = this.DUCKING_STATE;

		} //

		/*private function impHitGround( imp:Entity ):void {

			trace( "HIT HIT HIT ");
			imp.remove( Motion );
			this.curTimeline.gotoAndPlay( this.HIT_BEGIN );

		} // impHitGround()*/

		public function getImp():Entity {

			return this.imp;

		} //

		public function setImpCar( i:int ):void {

			// hide previous imp.

			this.curFerrisIndex = i;

			var stick:StickToEntity = this.imp.get( StickToEntity );
			stick.setEntity( this.cars[ i ] );

			this.impTimeline.gotoAndPlay( this.POPUP_BEGIN );
			this.curState = this.POPPING_STATE;

		} //

		/*public override function destroy():void {

			this.swings = null;
			this.curImp = null;
			this.curTimeline = null;

		} //*/

	} // End ImpGroup

} // End package