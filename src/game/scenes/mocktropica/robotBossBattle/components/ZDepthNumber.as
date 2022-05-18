package game.scenes.mocktropica.robotBossBattle.components {

	import flash.display.DisplayObject;

	import ash.core.Component;

	/**
	 * This component uses Number depths instead of int depths - which is better for objects
	 * actually moving through z-space instead of just being positioned at certain depths.
	 */
	public class ZDepthNumber extends Component {

		/**
		 * It's possible for the user to change the Display.displayObject while the ZDepthSystem is in use.
		 * This would mean the ZDepthSystem hash of displayObjects -> ZDepth components is now out of date.
		 * By saving the last used _displayObject, we can check for this problem.
		 */
		public var _displayObject:DisplayObject;
		//public var _container:DisplayObjectContainer;

		/**
		 * I renamed this from _invalidate to _updateDepth because there are some situations:
		 * ( empty Display components, changed displayObjects ) where you don't want to update the system.
		 * 
		 * In such cases, setting:
		 * zdepth._invalidate = false, is highly misleading.
		 * zdepth._updateDepth=false is more clear.
		 */
		public var _updateDepth:Boolean = true;

		public var fixed:Boolean = true;
		public var ignore:Boolean = false;

		private var _z:Number;

		public function ZDepthNumber( zValue:Number = 0 ) {

			if( !isNaN(zValue) ) {

				_z = zValue;				
			}

		} //

		public function get z():Number	{ return _z; }
		public function set z( zValue:Number ):void {

			if( zValue != z ) {
				_updateDepth = true;
				_z = zValue;
			}

		} // set z()

	} // class

} // package