package game.scenes.cavern1.visitorsCenter
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.entity.Dialog;
	import game.components.scene.SceneInteraction;
	import game.scenes.cavern1.shared.Cavern1Scene;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	
	public class VisitorsCenter extends Cavern1Scene
	{
		public function VisitorsCenter()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern1/visitorsCenter/";
			
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			setUpAntlers();
		}
		
		private function setUpAntlers():void
		{
			var clip:MovieClip = _hitContainer["antlers"];
			clip.mouseChildren = clip.mouseEnabled = false;
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip).add(new Id("antlers"));
			EntityUtils.visible(entity,shellApi.checkEvent(cavern1.RETURNED_ANTLERS),true);
			
			if(shellApi.checkHasItem(cavern1.ELK_ANTLERS))
				Dialog(getEntityById("rick").get(Dialog)).setCurrentById("foundAntlers");
		}
		
		override protected function onEventTriggered(event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == "use_elk_antlers")
			{
				var spatial:Spatial = player.get(Spatial);
				if(spatial.y < 1050 && spatial.x < 1950)
					SceneInteraction(getEntityById("rick").get(SceneInteraction)).activated = true;
			}
			else
				super.onEventTriggered(event, makeCurrent, init, removeEvent);
		}
	}
}