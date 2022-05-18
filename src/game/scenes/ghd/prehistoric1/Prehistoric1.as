package game.scenes.ghd.prehistoric1
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.ghd.GalacticHotDogScene;
	import game.scenes.ghd.shared.PrehistoricGroup;
	
	public class Prehistoric1 extends GalacticHotDogScene
	{
		private const DACTYL:String 		=		"dactyl";
		private const TRIGGER:String		=		"trigger";
		
		public function Prehistoric1()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/prehistoric1/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			this.shellApi.setUserField(_events.PLANET_FIELD, _events.PREHISTORIC, this.shellApi.island, true);
			
			
			var prehistoricGroup:PrehistoricGroup = this.addChildGroup( new PrehistoricGroup()) as PrehistoricGroup;
			prehistoricGroup.createDactyls( this, _hitContainer );
		}
	}
}