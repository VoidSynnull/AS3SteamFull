package game.scenes.custom.StarShooterSystem
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.FollowClipInTimeline;
	import game.components.entity.Parent;
	
	public class EnemyAiNode extends Node
	{
		public var enemyAi:EnemyAi;
		public var display:Display;
		public var spatial:Spatial;
		public var follow:FollowClipInTimeline
		public var parent:Parent;
	}
}