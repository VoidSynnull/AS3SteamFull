package game.scenes.deepDive2.pipeRoom.nodes
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.deepDive2.pipeRoom.components.Pipe;
	
	public class PipeNode extends Node
	{
		public var pipe:Pipe;
		
		public var spatial:Spatial;
		public var motion:Motion;
		public var id:Id;
	}
	
}