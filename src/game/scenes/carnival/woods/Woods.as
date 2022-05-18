package game.scenes.carnival.woods{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.data.animation.entity.character.Tremble;
	import game.scenes.carnival.CarnivalEvents;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	public class Woods extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		private var dan:Entity;
		
		public function Woods()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/woods/";
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
			
			_events = CarnivalEvents(events);
			shellApi.eventTriggered.add(handleEvents);
			dan = getEntityById("dan");
			loadDanRuns();
		}
		
		private function handleEvents(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.DAN_RAN_AWAY){
				danRuns();
			}
			if(event == "lock"){
				SceneUtil.lockInput(this, true, false);
			}
		}

		private function loadDanRuns():void
		{
			if(shellApi.checkEvent(_events.STARTED_BONUS_QUEST) && !shellApi.checkEvent(_events.DAN_RAN_AWAY)){
				CharUtils.setAnim(dan, Tremble);
			}else{
				removeDan();
			}
		}	
		
		private function danRuns():void
		{
			CharUtils.moveToTarget(dan, 1500, dan.get(Spatial).y, true, removeDan);
		}
		
		private function removeDan(...p):void
		{
			removeEntity(dan);
			unlock();
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this, false, false);
		}		

	}
}











