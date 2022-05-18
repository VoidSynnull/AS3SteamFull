package engine.nodes {
	
	import ash.core.Node;
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Spatial;
	
	public class PositionalAudioNode extends Node
	{
		public var audio:Audio;
		public var spatial:Spatial;
		public var range:AudioRange;
	}
	
}