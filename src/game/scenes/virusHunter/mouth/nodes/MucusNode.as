package game.scenes.virusHunter.mouth.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.mouth.components.Mucus;
	
	public class MucusNode extends Node
	{
		public var mucus:Mucus;
		public var spatial:Spatial;
		public var display:Display;
		public var motion:Motion;
	}
}