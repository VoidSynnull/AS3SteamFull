package game.scenes.cavern1.caveEntrance
{
	import ash.core.Node;
	
	import game.components.entity.Children;
	
	public class WaterGeyserNode extends Node
	{
		public var waterGeyser:WaterGeyser;
		public var children:Children;
		public var optional:Array = [Children];
	}
}