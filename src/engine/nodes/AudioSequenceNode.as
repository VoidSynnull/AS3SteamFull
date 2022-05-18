package engine.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.AudioSequence;
	
	public class AudioSequenceNode extends Node
	{
		public var audio:Audio;
		public var audioSequence:AudioSequence;
	}
}