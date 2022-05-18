package game.scenes.cavern1.surveySite
{
	import flash.display.DisplayObjectContainer;
	
	import engine.components.Spatial;
	
	import game.components.scene.SceneInteraction;
	import game.scenes.cavern1.shared.Cavern1Scene;
	
	public class SurveySite extends Cavern1Scene
	{
		public function SurveySite()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern1/surveySite/";
			
			super.init(container);
		}
		
		override protected function onEventTriggered(event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == "use_junior_id")
			{
				var spatial:Spatial = player.get(Spatial);
				if(spatial.x > 2200 && spatial.y < 950 && spatial.x < 3400)
				{
					SceneInteraction(getEntityById("winslow").get(SceneInteraction)).activated = true;
				}
			}
			else
				super.onEventTriggered(event, makeCurrent, init, removeEvent);
		}
	}
}