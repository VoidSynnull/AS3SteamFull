package game.components.audio
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.data.sound.SoundData;
	
	public class HitAudio extends Component
	{
		//public var hitId:String;
		public var active:Boolean;
		public var action:String;
		public var soundData:SoundData;
		public var hitEntity:Entity;
	}
}