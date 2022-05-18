package game.scenes.lands.shared.components {
	
	import ash.core.Component;
	
	public class SimpleTarget extends Component {

		public var targetX:Number;
		public var targetY:Number;

		public var slowRadius:Number;

		public var maxSpeed:Number = 6;

		public var vx:Number=0, vy:Number=0;
		/**
		 * the dx,dy to target is saved so it can be queried by other systems.
		 */
		public var dx:Number, dy:Number;

		/**
		 * this is the current distant from entity to target.
		 * it is computed by the SimpleTargetSystem so other systems can test against the value.
		 */
		public var targetDistance:Number = 0;

		public function SimpleTarget( tX:Number=0, tY:Number=0, stopRadius:Number=64 ) {

			this.slowRadius = stopRadius;

			this.targetX = tX;
			this.targetY = tY;

		} //
		
	} // class
	
} // package