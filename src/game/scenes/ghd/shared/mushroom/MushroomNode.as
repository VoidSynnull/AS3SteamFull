package game.scenes.ghd.shared.mushroom
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Id;
	
	import game.components.timeline.Timeline;
	
	public class MushroomNode extends Node
	{
		public var audio:Audio;
		public var mushroom:Mushroom;
		public var timeline:Timeline;
		public var id:Id;
	}
}