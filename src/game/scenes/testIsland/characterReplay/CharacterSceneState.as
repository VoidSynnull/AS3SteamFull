package game.scenes.testIsland.characterReplay
{
	import game.data.character.LookData;

	public class CharacterSceneState
	{
		public function CharacterSceneState()
		{
		}
		
		public var animation:Class;
		public var x:Number;
		public var y:Number;
		public var scaleX:Number;
		public var scaleY:Number;
		public var rotation:Number;
		public var lookData:LookData;
		public var startTime:Number;
		public var duration:Number;
	}
}