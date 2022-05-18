package game.nodes.ui
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.SpriteSheet;
	
	import game.components.input.Input;
	import game.components.ui.Cursor;
	
	public class CursorNode extends Node
	{
		public var cursor:Cursor;
		public var spatial:Spatial;
		public var spriteSheet:SpriteSheet;
		public var input:Input;
		public var display:Display;
		public var spatialOffset:SpatialOffset;
	}
}