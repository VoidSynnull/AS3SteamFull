package game.nodes.entity
{
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.character.ColorSet;
	import game.components.render.Line;
	import game.components.entity.Parent;
	import game.components.entity.character.DrawLimb;

	public class DrawLimbNode extends Node
	{
		public var drawLimb : DrawLimb 
		public var spatial : Spatial;
		public var display : Display;
		public var colorSet : ColorSet;
		public var line : Line;
		public var parent:Parent;
	}
}
