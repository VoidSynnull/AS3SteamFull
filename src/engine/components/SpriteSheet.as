package engine.components
{
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	import ash.core.Component;

	public class SpriteSheet extends Component
	{
		public function SpriteSheet()
		{
			_cache = new Dictionary();
		}
		
		public function retrieve(key:String):Vector.<BitmapData>
		{
			var sheet:Vector.<BitmapData> = _cache[key];
			
			return(sheet);
		}
		
		public function add(sheet:Vector.<BitmapData>, key:String):void
		{
			_cache[key] = sheet;
		}
		
		private var _cache:Dictionary;
	}
}