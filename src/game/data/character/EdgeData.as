package game.data.character
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import fl.motion.Motion;
	
	import game.util.DataUtils;
	
	/**
	 * Rig data for a particular character variant, contains PartData for all parts.
	 */
	public class EdgeData
	{
		public function EdgeData( id:String = "", top:Number = 0, bottom:Number = 0, right:Number = 0, left:Number = 0)
		{
			this.id = id;
			this.top = top;
			this.bottom = bottom;
			this.right = right;
			this.left = left;
			
			this.width = left + right;
			this.height = bottom + top;
		}

		public var top : Number;			
		public var bottom : Number;	
		public var right : Number;	
		public var left : Number;	
		
		public var width : Number;
		public var height : Number;
		
		private var _id : String;				// type of character/entity
		public function get id():String		{ return _id; }
		public function set id(value:String):void
		{
			if ( !DataUtils.validString( value ) )
			{
				_id = DEFAULT
			}
			else
			{
				_id = value;
			}
		}

		public static const DEFAULT:String = "default";
		
		public function isValid():Boolean
		{
			if ( isNaN( top ))		{ return false; }
			if ( isNaN( bottom ))	{ return false; }
			if ( isNaN( right ))	{ return false; }
			if ( isNaN( left ))		{ return false; }
			return true;
		}
	}
}