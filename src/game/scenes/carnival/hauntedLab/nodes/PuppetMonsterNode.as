package game.scenes.carnival.hauntedLab.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.carnival.hauntedLab.components.PuppetMonster;

	public class PuppetMonsterNode extends Node
	{
		public var puppetMonster:PuppetMonster;
		public var motion:Motion;
		public var spatial:Spatial;
		public var display:Display;
		public var timeline:Timeline;
		public var audio:Audio;
	}
}