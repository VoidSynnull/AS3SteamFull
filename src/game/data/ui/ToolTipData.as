package game.data.ui
{
	import flash.geom.Point;

	public class ToolTipData
	{
		public var type:String;
		public var hotSpot:Point;
		public var asset:String;
		public var transparentOnUp:Boolean;
		public var nativeCursor:Boolean;
		public var dynamic:Boolean; // set to true for cursors that have special code for display/positioning like the navigation arrow.
	}
}