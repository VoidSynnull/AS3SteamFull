package game.scenes.custom.StarShooterSystem
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	import game.components.timeline.Timeline;
	
	public class PatternNode extends Node
	{
		public var pattern:EnemyPattern;
		public var spatial:Spatial;
		public var display:Display;
		public var timeline:Timeline;
		public var children:Children;
	}
}