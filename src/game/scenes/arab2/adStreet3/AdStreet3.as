package game.scenes.arab2.adStreet3
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.data.character.LookData;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab2.Arab2Events;
	import game.util.CharUtils;
	
	public class AdStreet3 extends PlatformerGameScene
	{
		private var _events:Arab2Events;
		
		public function AdStreet3()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab2/adStreet3/";
			
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
			checkViz();
			super.loaded();
		}
		
		// TODO :: Much of this could be driven via the npcs.xml using events -  bard
		private function checkViz():void
		{
			if(shellApi.checkEvent(_events.VIZIER_FOLLOWING))
			{
				var look:LookData = new LookData();
				look.applyLook( "male", 0xd2aa72, 0x999999, "squint", "an_brokemerch", "astroking", "", "an2_vizier", "an2_vizier", "an2_vizier", "an2_vizier", "", "", "" );
				
				var charGroup:CharacterGroup = super.getGroupById( "characterGroup" ) as CharacterGroup;
				charGroup.createNpc( "vizier", look, player.get(Spatial).x, player.get(Spatial).y, "right","",null,onCharLoaded );
				
			}
		}
		
		private function onCharLoaded( charEntity:Entity = null ):void
		{
			CharUtils.followEntity(charEntity,player,new Point(150,100));
		}
	}
}