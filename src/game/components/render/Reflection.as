package game.components.render
{
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	public class Reflection extends Component
	{
		/**
		 * A dictionary specifying what Reflective bitmaps to draw to. This is compared to a Reflective's
		 * <code>type</code> property. If the dictionary has that type, it gets drawn.
		 */
		public var types:Dictionary = new Dictionary();
		
		/**
		 * These properties are extra parameters that can get used when a Reflection gets drawn to a Reflective
		 * bitmap. They are completely optional.
		 */
		public var colorTransform:ColorTransform;
		public var blendMode:String;
		public var clipRect:Rectangle;
		
		public function Reflection(types:Array = null)
		{
			if(types)
			{
				for each(var type:String in types)
				{
					this.types[type] = true;
				}
			}
			else this.types["default"] = true;
		}
	}
}