package game.scenes.carnival.shared.game3d.components {

	import flash.display.DisplayObject;
	
	import ash.core.Component;

	public class Spatial3D extends Component {

		public var x:Number;
		public var y:Number;
		public var z:Number;

		/**
		 * Coordinates in camera space. The camera z-coordinate: _cz
		 * is used to calculate depths, scaling and perspective.
		 */
		public var _cx:Number = 0;
		public var _cy:Number = 0;
		public var _cz:Number = 0;

		/**
		 * Recomputed each frame, used for both scaling and for perspective,
		 * so it's stored here to be used in both.
		 */
		public var focusScale:Number;

		/**
		 * If true, objects more distant from the 3D camera are scaled.
		 */
		public var enableScaling:Boolean = true;
		/**
		 * If true, objects have perspective applied to them, making objects approach
		 * the vanishing point when further from the camera.
		 * To-Do: Separate x,y,z vanishing points?
		 */
		public var enablePerspective:Boolean = false;

		/**
		 * If true, object will have its depths swapped so objects
		 * closer to the camera will appear in front.  Note that if the
		 * camera is rotated, this value cannot simply be z-based.
		 * 
		 * NOT CURRENTLY IMPLEMENTED. O DEAR.
		 */
		public var enableDepthSwapping:Boolean = true;

		/**
		 * Used to track changes in the display object for depth swapping.
		 */
		public var _displayObject:DisplayObject;
		/**
		 * Used to track if depth of clip should be updated in depth swapping.
		 */
		public var _updateDepth:Boolean = true;

		/**
		 * baseScale applied in addition to perspective scaling. This allows you to have a clip
		 * that's already scaled before 3d scaling is applied.
		 */
		//public var baseScale:Number = 1.0;

		public function Spatial3D( tx:Number=0, ty:Number=0, tz:Number=0 ) {

			this.x = tx;
			this.y = ty;
			this.z = tz;

			super();

		} //

		public function get cx():Number {
			return this._cx;
		}

		public function get cy():Number {
			return this._cy;
		}

		public function set cz( nz:Number ):void {

			if ( this._cz != nz ) {
				this._cz = nz;
				this._updateDepth = true;
			}

		} //

		public function get cz():Number {
			return this._cz;
		}

	} // End Spatial3D
	
} // End package