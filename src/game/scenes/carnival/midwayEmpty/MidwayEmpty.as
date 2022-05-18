package game.scenes.carnival.midwayEmpty{
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.data.animation.entity.character.Grief;
	import game.scenes.carnival.CarnivalEvents;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	
	public class MidwayEmpty extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		private var sissy:Entity;
		private var bubby:Entity;
		
		public function MidwayEmpty()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/midwayEmpty/";
			
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
			_events = CarnivalEvents(events);
			shellApi.eventTriggered.add(handleEvents);
			sissy = getEntityById("sissy");
			bubby = getEntityById("bubby");
			super.loaded();		
		}	
		
		private function handleEvents(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "bubbyPose"){
				CharUtils.setAnim(bubby, Grief);
			}
			else if(event == "sissyPose"){
				CharUtils.setAnim(sissy, Grief);
			}
		}		
		
	}
}







