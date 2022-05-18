package game.scenes.myth.shared.components
{
	import flash.display.Sprite;
	
	import ash.core.Component;
	import engine.components.Display;
	
	public class ElectrifyComponent extends Component
	{
		public var shockDisplay:Display;
		
		public var sparks:Vector.<Sprite> = new Vector.<Sprite>;
		public var childNum:Vector.<int> = new Vector.<int>;
		public var lastX:Vector.<Number> = new Vector.<Number>;
		public var lastY:Vector.<Number> = new Vector.<Number>;
		
		public var on:Boolean = true;
	}
}

