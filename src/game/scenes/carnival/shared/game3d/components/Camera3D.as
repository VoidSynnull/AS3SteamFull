package game.scenes.carnival.shared.game3d.components {

	import flash.geom.Vector3D;
	
	import ash.core.Component;

	/**
	 * NOTE: the perennial problem in these systems is matching cameras with the objects they display.
	 * For now I'm just going to make the system a single-camera one. In the future, cameras might
	 * automatically collect their display objects by comparing Spatial3D camera_id numbers?
	 */
	public class Camera3D extends Component {

		static private var NextId:int = 0;

		/**
		 * Don't change this. Each object with a 3D spatial will be assigned
		 * to a camera with an id, or camera 0 if the object doesn't
		 * give an id.
		 */
		private var _id:int;

		public var location:Vector3D;

		/**
		 * Used to define the orientation of the camera. Possibly replace with a Matrix3D when I
		 * understand those better. Z axis always looks straight ahead from the camera.
		 */
		public var axisX:Vector3D = new Vector3D( 1, 0, 0 );
		public var axisY:Vector3D = new Vector3D( 0, 1, 0 );
		public var axisZ:Vector3D = new Vector3D( 0, 0, 1 );

		/**
		 * Until I decide how multiple cameras are handled, there will only
		 * actually be one active camera. :\
		 */
		public var active:Boolean = true;

		/**
		 * By default it will be assumed that the camera does not rotate it's axes,
		 * as this is rare in a game like poptropica. This can enable faster camera
		 * coordinate transformations because objects don't need to project onto
		 * camera axes.
		 * 
		 * If you want the camera to rotate, set this value to false.
		 */
		public var axisAlignedCamera:Boolean = true;

		public var _frustum:Frustum;

		public function Camera3D( x:Number=0, y:Number=0, z:Number=0 ) {

			this.location = new Vector3D( x, y, z );

			this._id = Camera3D.NextId++;

			super();

		}

		public function getScaleAtCameraZ( cz:Number ):Number {

			return this._frustum.focus_dist / ( this._frustum.focus_dist - cz );

		} //

		[Inline]
		public function get id():int {

			return this._id;

		} //

	} // End Camera3D

} // End package