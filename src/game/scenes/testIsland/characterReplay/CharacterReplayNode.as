package game.scenes.testIsland.characterReplay
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	public class CharacterReplayNode extends Node
	{
		public var characterReplay:CharacterReplayComponent;
		public var current:CurrentCharacterSceneState;
		public var spatial:Spatial;
	}
}