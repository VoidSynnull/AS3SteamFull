package game.scenes.testIsland.characterReplay
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class CharacterReplayComponent extends Component
	{		
		public function CharacterReplayComponent()
		{
			this.states = new Vector.<CharacterSceneState>();
			
			super();
		}
		
		public var states:Vector.<CharacterSceneState>;
		public var play:Boolean = false;
		public var replayTime:Number = 0;
		public var record:Boolean = false;
		public var recordTime:Number = 0
		public var source:Entity;
		public var sampleRate:Number = 0;
		public var timeSinceLastSample:Number = 0;
		public var randomSamples:Boolean = false;
	}
}