package game.scenes.arab1.palaceInterior
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.Dialog;
	import game.components.motion.Destination;
	import game.data.TimedEvent;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab1.Arab1Events;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	public class PalaceInterior extends PlatformerGameScene
	{
		public function PalaceInterior()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab1/palaceInterior/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var arab:Arab1Events;
		private var sultan:Entity;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			arab = events as Arab1Events;
			
			sultan = getEntityById("sultan");
			
			findMyLamp();
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			if(!shellApi.checkEvent(arab.ENTERED_PALACE)){
				SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, enterPalacePhoto));
			}
		}
		
		private function enterPalacePhoto(...p):void
		{
			shellApi.triggerEvent(arab.ENTERED_PALACE, true);
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == arab.QUEST_ACCEPTED)
			{
				shellApi.getItem(arab.CROWN_JEWEL, null, true)
			}
			
			if(event == arab.LAMP)
			{
				walkToSultan();
			}
		}
		
		private function walkToSultan():void
		{
			SceneUtil.lockInput(this);
			var spatial:Spatial = sultan.get(Spatial);
			var destination:Destination = CharUtils.moveToTarget(player, spatial.x + 75, spatial.y, true, commentOnLamp);
			destination.validCharStates = new <String>["stand"];
		}
		
		private function commentOnLamp(entity:Entity):void
		{
			var dialog:Dialog = sultan.get(Dialog);
			dialog.sayById("lamp");
			dialog.complete.add(findMyLamp);
		}
		
		private function findMyLamp(...args):void
		{
			SceneUtil.lockInput(this, false);
			if(shellApi.checkEvent(arab.QUEST_ACCEPTED))
				Dialog(sultan.get(Dialog)).setCurrentById("findMyLamp");
			else
				Dialog(sultan.get(Dialog)).setCurrentById("quest");
		}
	}
}