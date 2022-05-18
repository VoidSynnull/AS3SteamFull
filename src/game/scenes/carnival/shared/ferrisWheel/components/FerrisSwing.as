package game.scenes.carnival.shared.ferrisWheel.components {
	
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import game.components.hit.Mover;

	/**
	 * A ferris wheel swing rotates at a fixed radius around a ferris wheel axle,
	 * but also swings on its own - like a ferris wheel car, for example.
	 * 
	 */
	public class FerrisSwing extends Component {

		/**
		 *  distance of swing to axle. set by ferriswheelsystem
		 */
		public var radius:Number;

		/**
		 * Offset of the swing in radians from the ferris axle's axis.
		 */
		public var axisAngle:Number;

		public var centerOfMass:Point;

		/**
		 * For swinging seats, the restoring spring constant to keep the seat level.
		 */
		public var restoreSpring:Number = 0.1;

		public function FerrisSwing( centerPt:Point=null ) {

			super();

			if ( centerPt != null ) {
				this.centerOfMass = centerPt;
			}

		} //

	} // End FerrisSwing

} // End package