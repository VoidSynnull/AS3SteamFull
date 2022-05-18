package game.scenes.deepDive1.maze.components
{
	import ash.core.Component;
	import ash.core.Entity;

	public class UrchinHazards extends Component
	{
		public var allUrchinHazards:Vector.<Entity> = new Vector.<Entity>; // all hazard entities including stationary urchin entities;
		public var player:Entity; // player/sub entity
	}
}