package game.scenes.carnival.shared.game3d.components {

	import flash.geom.Point;
	
	import ash.core.Component;


	/**
	 * This component (with the FrustumSystem) will scale and reposition objects based
	 * on the 3d viewing volume.
	 * 
	 * This class replicates a lot of the functionality of displayObject.z + perspectiveProjection
	 * but gives slightly more control.
	 */
	public class Frustum extends Component {

		/**
		 * Point on the display which represents the camera center.
		 */
		public var projectionCenter:Point;

		/**
		 * focal_length is the distance from the projection center to the focal point.
		 * The focal_length should be negative. A focal_length of zero is right out.
		 * 
		 * A large negative focus (e.g. -10000) means very little perspective and scaling.
		 * A small negative focus (e.g. -10) means extreme perspective and scaling.
		 * 
		 * display_coord = original_coord * focus/(focus - d)
		 * where distance is the distance from the camera origin to the object
		 * (d is usually z but not in the case where a camera is translated/rotated)
		 */
		public var focus_dist:Number;

		public function Frustum( centerX:Number=0, centerY:Number=0, focus:Number=-100 ) {

			super();

			this.projectionCenter = new Point( centerX, centerY );
			this.focus_dist = focus;

		} //

	} // End Frustum
	
} // End package