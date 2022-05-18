package game.components.entity
{	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Component;
	
	public class ZDepth extends Component
	{
		public function ZDepth( zValue:Number = NaN )
		{
			if( !isNaN(zValue) )
			{
				_z = zValue;
				
			}

		}
		
		private var _z:int;
		public function get z():int	{ return _z; }
		public function set z( zValue:int ):void
		{
			if( zValue != z )
			{
				_updateDepth = true;
				_z = zValue;
			}
		}

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

		// temporary for backwards compatibility.
		public var _invalidate:Boolean = true;

		public var fixed:Boolean = true;
		public var ignore:Boolean = false;
	}
}