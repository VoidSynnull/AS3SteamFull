package game.nodes.audio
{
	import ash.core.Node;
	import engine.components.Audio;
	import game.components.audio.HitAudio;
	import game.components.hit.CurrentHit;
	
	public class HitAudioNode extends Node
	{
		public var audio:Audio;
		public var currentHit:CurrentHit;
		public var hitAudio:HitAudio;
	}
}