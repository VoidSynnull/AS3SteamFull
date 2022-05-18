package game.scenes.lands.shared.nodes {

	import ash.core.Node;
	
	import engine.components.Audio;
	
	import game.scenes.lands.shared.components.FocusTileComponent;
	import game.scenes.lands.shared.components.LandEditContext;
	import game.scenes.lands.shared.components.LandGameComponent;
	import game.scenes.lands.shared.components.LandHiliteComponent;
	import game.scenes.lands.shared.components.LightningStrike;
	import game.scenes.lands.shared.components.LightningTarget;
	import game.scenes.lands.shared.components.TileBlaster;

	public class LandEditNode extends Node {

		public var editContext:LandEditContext;
		//public var lightning:LightningStrike;

		public var strikeTarget:LightningTarget;

		public var blaster:TileBlaster;			// used to explode tiles.
		public var audio:Audio;

		public var game:LandGameComponent;

		public var hilite:LandHiliteComponent;
		public var focus:FocusTileComponent;

	} //

} // package