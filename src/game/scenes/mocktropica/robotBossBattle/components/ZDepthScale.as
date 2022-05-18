package game.scenes.mocktropica.robotBossBattle.components {

	import ash.core.Component;

	/**
	 * Simplified 3d scaling effect. Indicates the amount of scaling to perform on
	 * a clip based on its zdepth.
	 * 
	 * Note that clip coordinates are not changed, view centers can't be defined, etc
	 * like you would in a more general 3d system. this is just for quick scaling.
	 */
	public class ZDepthScale extends Component {

		public var focus:Number;

		/**
		 * Focus z should be a negative number. More negative numbers produce less scaling,
		 * while numbers close to zero produce drastic scaling.
		 */
		public function ZDepthScale( focus_z:Number=-100 ) {

			this.focus = focus_z;

		} //

		/**
		 * Later add some functions for computing good focus distances
		 * for desired scaling effects.
		 * 
		 */

	} // End ZDepthControl
	
} // End package