// Used by:
// Card "crispy_rice_treats" on timmy island using item crispy_rice_treats

package game.data.specialAbility.islands.timmy
{	
	import game.components.entity.Dialog;
	import game.data.specialAbility.character.ThrowItem;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.timmy.TimmyEvents;
	
	/**
	 * Throw treat item only if Total_Following event exists 
	 */
	public class ThrowTreat extends ThrowItem
	{
		private var _events:TimmyEvents;
		private const SAVE_TREATS:String 	=	"save_treats";
		private const SCHOOL:String 		=	"School";
		private const TOTAL:String 			=	"total";
		 
		override public function activate(node:SpecialAbilityNode):void
		{
			if( super.group.getEntityById( TOTAL ))
			{
				if(this.shellApi.checkEvent(_events.TOTAL_FOLLOWING))
				{
					if( this.shellApi.sceneName == SCHOOL && shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "5" ) && shellApi.checkEvent( _events.TOTAL_FOLLOWING ) && !shellApi.checkEvent( _events.FREED_ROLLO ))
					{
						this.shellApi.triggerEvent(_events.USE_TREATS_SCHOOL);
					}
					else
					{
						super.activate(node);
					}
				}
				else if(!this.shellApi.checkEvent(_events.TOTAL_PRESENT))
				{
					this.shellApi.triggerEvent(_events.CALL_TOTAL);
				}
				else
				{
					super.activate(node);
				}
			}
			else if( this.shellApi.sceneName == "TimmysHouse" && this.shellApi.checkEvent(_events.TOTAL_IN_HOUSE))
			{
				this.shellApi.triggerEvent(_events.CALL_TOTAL);
			}
			else
			{
				var dialog:Dialog 			=	node.entity.get( Dialog );
				dialog.sayById( SAVE_TREATS );
			}
		}
	}
}