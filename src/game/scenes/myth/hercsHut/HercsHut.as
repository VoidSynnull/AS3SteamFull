package game.scenes.myth.hercsHut
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.components.entity.Dialog;
	import game.scenes.myth.shared.Mirror;
	import game.scenes.myth.shared.MythScene;
	
	public class HercsHut extends MythScene
	{
		public function HercsHut()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/hercsHut/";
			
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
			super.shellApi.eventTriggered.add(eventTriggers);
			setupHercDialog();
		}
		
		// process incoming events
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if( event == _events.HERCULES_FOLLOWING )
			{
				if( !agreed )
				{
					showPopup();
				}
			}
			
			if( event == _events.USE_MIRROR )
			{
				showPopup(); 
			}
			
			if( event == _events.NOT_APHRODITE || event == _events.NOT_HADES || event == _events.NOT_POSEIDON || event == _events.NOT_ZEUS )
			{
				var entity:Entity = super.getEntityById( "herc" );
				var dialog:Dialog = entity.get( Dialog );
				
				dialog.sayById( event + "_text" )
			}
		}
		
		private function setupHercDialog():void
		{
			var dialog:Dialog = getEntityById("herc").get(Dialog);
			
			if(shellApi.checkEvent(_events.HERCULES_FOLLOWING))
			{
				dialog.setCurrentById("herc_follow");
			}
			else if(shellApi.checkEvent(_events.CAN_TRANSPORT_HERCULES))
			{
				dialog.setCurrentById("transport_convo");
			}
			else if(shellApi.checkEvent(_events.ZEUS_APPEARS_STEAL))
			{
				dialog.setCurrentById("zeus_stole");
			}
			else if(shellApi.checkEvent(_events.ZEUS_APPEARS_TREE))
			{
				dialog.setCurrentById("apple");
			}
		}
		
		private function showPopup():void
		{
			var popup:Mirror = super.addChildGroup( new Mirror( super.overlayContainer, true )) as Mirror;
			popup.id = "mirror";
			agreed = true;
		}
		
		private var agreed:Boolean = false;
	}
}