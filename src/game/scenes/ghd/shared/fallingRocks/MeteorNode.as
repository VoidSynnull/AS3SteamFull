package game.scenes.ghd.shared.fallingRocks
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	import game.components.hit.Hazard;
	
	public class MeteorNode extends Node
	{
		public var meteor:Meteor;
		public var spatial:Spatial;
		public var motion:Motion;
		public var display:Display;
		public var id:Id;
		public var hazard:Hazard;
		
		// holds particle emmiter
		public var child:Children;
	}
}