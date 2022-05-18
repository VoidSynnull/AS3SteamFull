package game.scenes.carnival.shared.game3d.components {
	
	import ash.core.Component;

	/**
	 * Applies a constant force to an object every frame.
	 */
	public class ConstantForce3D extends Component {

		public var x:Number;
		public var y:Number;
		public var z:Number;

		public function ConstantForce3D( fx:Number=0, fy:Number=0, fz:Number=0 ) {

			super();

			this.x = fx;
			this.y = fy;
			this.z = fz;

		} //

	} // End Force3D

} // End package