package game.scenes.mocktropica.robotBossBattle.components {

	import ash.core.Component;

	public class HitBox3D extends Component {

		public var halfHeight:Number;
		public var halfWidth:Number;
		public var halfDepth:Number;

		public function HitBox3D( width:Number, height:Number, depth:Number ) {

			super();

			this.halfHeight = height/2;
			this.halfWidth = width/2;
			this.halfDepth = depth/2;

		} //

		/**
		 * Checking the 2d overlap can be useful when the z-component isn't important.
		 */
		/*public function check2DHit( hitBox:HitBox3D ):void {
		} //*/

	} // End HitBox3D

} // End package