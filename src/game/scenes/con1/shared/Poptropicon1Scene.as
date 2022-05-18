package game.scenes.con1.shared
{
	import game.components.entity.Dialog;
	import game.components.entity.character.Skin;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.con1.Con1Events;
	import game.util.SkinUtils;

	public class Poptropicon1Scene extends PlatformerGameScene
	{
		public function Poptropicon1Scene()
		{
			super();
		}
		
		// all assets ready
		override public function loaded():void
		{
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			_events = shellApi.islandEvents as Con1Events;
			
			newLookApplied();
			Skin(player.get(Skin)).lookLoadComplete.add(newLookApplied);
			
			shellApi.eventTriggered.add(handleEventTrigger);
			
			super.loaded();
		}
		
		// Override in subclasses
		public function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event.indexOf(_events.GIVE) != -1)
			{
				var itemId:String = event.slice(_events.GIVE.length);
				if(itemId == _events.JETPACK)
					Dialog(player.get(Dialog)).sayById("jetpack_wrong");
				else if(itemId == _events.FREMULON_MASK)
					Dialog(player.get(Dialog)).sayById("no_use");
			}					
		}
		
		private function newLookApplied():void
		{
			// Check if player is wearing the wizard outfit
			if(SkinUtils.hasSkinValue(player, SkinUtils.FACIAL, "poptropicon_wizard") &&
				SkinUtils.hasSkinValue(player, SkinUtils.HAIR, "poptropicon_wizard") &&
				SkinUtils.hasSkinValue(player, SkinUtils.PACK, "poptropicon_wizard") &&
				SkinUtils.hasSkinValue(player, SkinUtils.OVERSHIRT, "poptropicon_wizard"))
			{
				shellApi.completeEvent(_events.DRESSED_AS_WIZARD);
				shellApi.removeEvent(_events.SOME_WIZARD_PARTS);
			}
			else if(SkinUtils.hasSkinValue(player, SkinUtils.FACIAL, "poptropicon_wizard") ||
				SkinUtils.hasSkinValue(player, SkinUtils.HAIR, "poptropicon_wizard") ||
				SkinUtils.hasSkinValue(player, SkinUtils.PACK, "poptropicon_wizard") ||
				SkinUtils.hasSkinValue(player, SkinUtils.OVERSHIRT, "poptropicon_wizard"))
			{
				shellApi.completeEvent(_events.SOME_WIZARD_PARTS);
				shellApi.removeEvent(_events.DRESSED_AS_WIZARD);
			}
			else
			{
				shellApi.removeEvent(_events.DRESSED_AS_WIZARD);
				shellApi.removeEvent(_events.SOME_WIZARD_PARTS);
			}
			
			if( SkinUtils.hasSkinValue( player, SkinUtils.MARKS, "poptropicon_thor" ))
			{
				SkinUtils.emptySkinPart( player, SkinUtils.FACIAL );
			}
		}
		
		protected var _audioGroup:AudioGroup;
		protected var _events:Con1Events;
	}
}