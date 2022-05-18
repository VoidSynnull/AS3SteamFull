package game.scenes.viking.river.raftEddyCollision
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.WaveMotion;
	
	public class RaftNode extends Node
	{
		public var raft:Raft;
		public var spatial:Spatial;
		public var display:Display;
		public var wave:WaveMotion;
	}
}