package game.scenes.virusHunter.heart.components {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.heart.components.virusStates.QuadVirusState;
	import game.scenes.virusHunter.heart.components.virusStates.VirusMultiState;

	public class QuadVirus extends Component {

		static public const FIGHTING:int = 1;
		static public const RUNNING:int = 2;
		static public const INTRO:int = 3;
		static public const DYING:int = 4;
		static public const DEAD:int = 5;

		public var entity:Entity;
		public var group:Group;

		public var container:DisplayObjectContainer;
		public var clip:MovieClip;

		public var targetMoveX:Number;
		public var targetMoveY:Number;

		public var state:int;
		public var curState:QuadVirusState;

		// Simple target move for running away from player. Going offscreen, etc.
		public var targetMove:Boolean = false;
		public var targetX:Number;
		public var targetY:Number;

		public var onTargetDone:Function;		// onTargetDone( virusEntity:Entity )
		public var onVirusWounded:Function;		// Called when the virus loses an arm. No parameters.

		public var hitCooldown:Number = 1.5;

		public var body:Entity;

		public var hittable:Boolean = true;

		public var armEntities:Vector.<Entity>;
		public var arms:Vector.<RigidArm>;

		public function QuadVirus() {

			arms = new Vector.<RigidArm>();

		} //

		// called by the system when all the local variable stuff is set.
		public function init():void {

			var e:Entity;
			var sleep:Sleep;

			for( var i:int = armEntities.length-1; i >= 0; i-- ) {

				e = armEntities[i];
				if ( e == null ) {
					continue;
				}
				sleep = e.get( Sleep );
				if ( sleep == null ) {
					continue;
				}
				sleep.ignoreOffscreenSleep = true;

			} //

		} // init()

		// stop all the arm,segment omegas.
		public function stopArms():void {

			for( var i:int = arms.length-1; i >= 0; i-- ) {

				arms[ i ].stop();
				
			} //

		} //

		public function restoreArms():void {

			var e:Entity;
			for( var i:int = armEntities.length-1; i >= 0; i-- ) {
				
				e = armEntities[ i ];

				( e.get( RigidArmMode ) as RigidArmMode ).curMode = RigidArmMode.RESTORE;
				arms[ i ].followParents = false;
				
			} //

		} //

		public function waveArms():void {

			var e:Entity;
			for( var i:int = armEntities.length-1; i >= 0; i-- ) {

				e = armEntities[ i ];

				if ( e.get(ArmWave) == null ) {
					e.add( new ArmWave(), ArmWave );
				}
				( e.get( RigidArmMode ) as RigidArmMode ).curMode = RigidArmMode.SWAY;
				arms[ i ].followParents = true;

			} //

		} // waveArms()

		public function endArmWave():void {

			var e:Entity;
			for( var i:int = armEntities.length-1; i >= 0; i-- ) {

				e = armEntities[ i ];

				e.remove( ArmWave );
				( e.get( RigidArmMode ) as RigidArmMode ).removeMode( RigidArmMode.SWAY );
				arms[ i ].followParents = false;

			} //

		} //

		/*public function setArmSleep( sleeping:Boolean ):void {

			var e:Entity;
			var sleep:Sleep;

			for( var i:int = childArms.length-1; i >= 0; i-- ) {

				e = childArms[i];
				if ( e == null ) {
					continue;
				}
				sleep = e.get( Sleep );
				if ( sleep == null ) {
					continue;
				}
				sleep.sleeping = sleeping;
				
			} //

		} //*/

		public function pushArm( rigidArm:RigidArm ):void {

			arms.push( rigidArm );

		} //

		public function getArm( i:int ):RigidArm {

			if ( i >= arms.length ) {
				i = arms.length-1;
			}

			return arms[i];

		} //

		public function setState( state:QuadVirusState ):void {

			curState = state;
			state.start();

			hittable = true;			// need this somewhere. why not here?

		} //

		public function doMultiMode( states:Vector.<QuadVirusState> ):void {

			setState( new VirusMultiState( entity, states ) );

		} //

		// make all the arms target the player.
		public function targetPlayer():void {

			//var mode:RigidArmMode;

			for( var i:int = armEntities.length-1; i >= 0; i-- ) {

				if ( ( armEntities[ i ].get(Id) as Id ).id == "topArm" ) {
					continue;
				}

				( armEntities[ i ].get( RigidArmMode ) as RigidArmMode ).curMode = RigidArmMode.TARGET;

				//mode.addMode( RigidArmMode.TARGET );

			} // end for-loop.

		} //

		public function setArmMode( modeCode:uint ):void {

			for( var i:int = armEntities.length-1; i >= 0; i-- ) {

				armEntities[ i ].get( RigidArmMode ).curMode = modeCode;

			} // end for-loop.

		} //

		// make all the arms target the player.
		public function endTarget():void {

			var mode:RigidArmMode;

			for( var i:int = armEntities.length-1; i >= 0; i-- ) {

				mode = armEntities[ i ].get( RigidArmMode );
				mode.removeMode( RigidArmMode.TARGET );

			} // end for-loop.

		} //

		public function doTargetMove( x:Number, y:Number ):void {

			targetMove = true;

			targetX = x;
			targetY = y;

			var sleep:Sleep = entity.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			sleep.sleeping = false;

		} //

		public function endTargetMove():void {

			var sleep:Sleep = entity.get( Sleep );
			sleep.ignoreOffscreenSleep = false;

			targetMove = false;

			if ( onTargetDone != null ) {
				onTargetDone( entity );
			} //

		} //

		public function stopMotion():void {
			
			var motion:Motion = entity.get( Motion );
			
			motion.velocity.x = motion.velocity.y = 0;
			motion.acceleration.x = motion.acceleration.y = 0;
			motion.previousAcceleration.x = motion.previousAcceleration.y = 0;
			motion.rotationVelocity = 0;
			
			targetMove = false;
			
		} //
		
		public function setPosition( x:Number, y:Number, angle:Number=0 ):void {

			var spatial:Spatial = entity.get( Spatial ) as Spatial;

			clip.x = spatial.x = x;
			clip.y = spatial.y = y;
			clip.rotation = spatial.rotation = angle;

		} //

		/*public function disableArm( arm:Entity ):void {

			var display:Display
			var sleep:Sleep = arm.get( Sleep );
			var rigidArm:RigidArm = arm.get( RigidArm );

			var seg:Entity;

			sleep.sleeping = true;
			sleep.ignoreOffscreenSleep = true;

			var segments:Vector.<Entity> = ( arm.get( RigidArm ) as RigidArm ).segments;
			for( var i:int = segments.length-1; i >= 0; i-- ) {

				seg = segments[i];

				display = seg.get( Display );
				display.visible = false;

				sleep = seg.get( Sleep );
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = true;

			} // end-for.

		} // disableArm()*/

		/*public function enableArm( arm:Entity ):void {

			var display:Display
			var sleep:Sleep = arm.get( Sleep );
			//var rigidArm:RigidArm = arm.get( RigidArm );

			var seg:Entity;

			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = false;

			var segments:Vector.<Entity> = ( arm.get( RigidArm ) as RigidArm ).segments;
			for( var i:int = segments.length-1; i >= 0; i-- ) {

				seg = segments[i];

				display = seg.get( Display );
				display.visible = true;

				sleep = seg.get( Sleep );
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = false;

			} // end-for.

		} // enableArm()*/

	} // End QuadVirus

} // End package