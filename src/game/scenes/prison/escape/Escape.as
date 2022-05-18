package game.scenes.prison.escape
{
	import game.scene.template.CutScene;
	import game.scenes.prison.PrisonEvents;
	import game.scenes.prison.hill.Hill;
	
	public class Escape extends CutScene
	{
		protected var _events:PrisonEvents;
		
		public function Escape()
		{
			super();
			configData("scenes/prison/escape/", null);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			_events = shellApi.islandEvents as PrisonEvents;
			
			if(!this.shellApi.checkEvent(_events.PLAYER_ESCAPED)){
				this.shellApi.completeEvent(_events.PLAYER_ESCAPED);
			}
		}
		
		override public function end():void
		{
			super.end();
			
			this.shellApi.loadScene(Hill, 1780, 2921, "left");
		}
	}
}

