package game.components.ui
{
	import flash.ui.MouseCursorData;
	
	import ash.core.Component;
	
	public class Cursor extends Component
	{
		public function Cursor(defaultType:String = null)
		{
			if(defaultType != null)
			{
				this.type = this.defaultType = defaultType;
			}
		}
		
		public function set type(type:String):void
		{
			if(_type != type)
			{
				_invalidate = true;
				_type = type;
			}
		}
		
		public function get type():String { return(_type); }
		
		public var defaultType:String;
		public var _invalidate:Boolean = false;
		public var transparent:Boolean = false;
		public var _cursorData:MouseCursorData;
		private var _type:String;
	}
}