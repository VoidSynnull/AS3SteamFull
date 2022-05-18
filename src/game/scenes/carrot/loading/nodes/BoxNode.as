package game.scenes.carrot.loading.nodes 
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.carrot.loading.components.Box;

	public class BoxNode extends Node
	{
		public var box:Box;
		public var spatial:Spatial;
		//public var display:Display;
		public var motion:Motion;
		public var id:Id;
		public var audio:Audio;
	}
}