package game.scenes.myth.riverStyx.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.myth.riverStyx.components.StyxComponent;
	
	public class StyxNode extends Node
	{
		public var audio:Audio;
		public var id:Id;
		public var motion:Motion;
		public var spatial:Spatial;
		public var styx:StyxComponent;
		
		public var sleep:Sleep; 
		public var optional:Array = [ Sleep ];
	}
}