package game.scenes.shrink.silvaOfficeShrunk01.ShrinkSystem
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	public class ShrinkNode extends Node
	{
		public var audio:Audio;
		public var display:Display;
		public var id:Id;
		public var shrink:Shrink;
		public var spatial:Spatial;
		public var tween:Tween;
	}
}