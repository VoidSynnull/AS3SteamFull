package game.scenes.mocktropica.robotBossBattle.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	public class MoveTarget3D extends Component {

		public var x:Number;
		public var y:Number;
		public var z:Number;

		public var slowRadius:Number = 100;
		public var stopRadius:Number = 50;

		public var active:Boolean = false;
		public var useVelocityTarget:Boolean = false;

		/**
		 * max accelerations when accelerating towards a target and breaking.
		 */
		public var acceleration:Number = 500;
		/**
		 * Really there needs to be a separate Driving component that gives
		 * different types of accelerating that can be used by Steering systems.
		 * This is very ad-hoc.
		 */
		public var decceleration:Number = 2000;

		/**
		 * If continuous is set to true, the target will be tracked continuously -
		 * there will be no absolutely stopping at the target and no signals
		 * will fire when the target is reached.
		 */
		public var continuous:Boolean = false;

		/**
		 * velocity targets for when useVelocityTarget = true
		 */
		public var velocityX:Number;
		public var velocityY:Number;
		public var velocityZ:Number;

		/**
		 * onReachedTarget( e:Entity ) why not
		 */
		public var onReachedTarget:Signal;

		public function MoveTarget3D( tx:Number=0, ty:Number=0, tz:Number=0 ) {

			this.x = tx;
			this.y = ty;
			this.z = tz;

			this.onReachedTarget = new Signal( Entity );

		} //

		public function setVelocityTarget( tvx:Number, tvy:Number, tvz:Number ):void {

			this.velocityX = tvx;
			this.velocityY = tvy;
			this.velocityZ = tvz;

			this.useVelocityTarget = true;
			this.active = true;

		} //

		public function setTarget( tx:Number, ty:Number, tz:Number=0 ):void {

			this.x = tx;
			this.y = ty;
			this.z = tz;

			this.useVelocityTarget = false;
			this.active = true;

		} //

	} // End MoveTarget

} // End package