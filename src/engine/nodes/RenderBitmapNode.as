package engine.nodes
{
	import engine.components.DisplayBitmap;
	import ash.core.Node;
	import engine.components.Display;
	import engine.components.Spatial;

	public class RenderBitmapNode extends Node
	{
		public var spatial : Spatial;
		public var display : DisplayBitmap;
	}
}
