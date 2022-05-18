package game.scenes.viking.adStreet2
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	
	import game.components.entity.Dialog;
	import game.components.scene.SceneInteraction;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.viking.shared.popups.MapPopup;
	
	import org.osflash.signals.Signal;
	
	public class AdStreet2 extends PlatformerGameScene
	{
		public function AdStreet2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/adStreet2/";
			
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
			
			setupMapDoor();
		}
		
		private function setupMapDoor():void {
			var door:Entity = super.getEntityById("exitRight");
			var scenenteraction:SceneInteraction = door.get(SceneInteraction);
			var mapDoorinteraction:Interaction = door.get(Interaction);
			scenenteraction.offsetX = 0;
			mapDoorinteraction.click = new Signal();
			mapDoorinteraction.click.add(openMap);			
			
		}
		
		private function openMap(door:Entity):void {
			var mapPopup:MapPopup = new MapPopup(overlayContainer);
			addChildGroup(mapPopup);
		}
	}
}