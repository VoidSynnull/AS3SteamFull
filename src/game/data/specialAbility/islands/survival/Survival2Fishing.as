// Used by:
// Card "fishingPole" on survival2 island using item fishing_pole

package game.data.specialAbility.islands.survival
{
	import flash.display.MovieClip;
	
	import game.components.entity.Dialog;
	import game.data.specialAbility.islands.survival.Fishing;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.survival2.Survival2Events;
	
	/**
	 * Fishing pole shows line if has shoelaces, hook and bait
	 */
	public class Survival2Fishing extends Fishing
	{
		private var _events:Survival2Events = new Survival2Events();
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			
			if(scene != null)
				determineShowLine( partDisplay);
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			determineShowLine( partDisplay);
			
			// if hook has not been attached to pole, do nothing
			if( !super.shellApi.checkItemUsedUp(_events.HOOK) ) 	
			{
				Dialog(node.entity.get(Dialog)).sayById("no_hook");
				return; 
			}
			
			var shoelace1:Boolean = super.shellApi.checkItemUsedUp(_events.SHOELACE1);
			var shoelace2:Boolean = super.shellApi.checkItemUsedUp(_events.SHOELACE2);
			
			if(shoelace1 && shoelace2){
				_defaultLineLength = 425;
			}
			else if(shoelace1 || shoelace2){
				_defaultLineLength = 265;
			}

			// just checks for bait field locally
			super.bait = super.shellApi.getUserField(_events.BAIT_FIELD, super.shellApi.island) as String;
			if(!super.bait)
			{
				super.bait = "none";
			}

			super.activate(node);
		}
		
		private function determineShowLine( partDisplay:MovieClip):Boolean
		{
			if( super.shellApi.checkItemUsedUp(_events.SHOELACE2) || super.shellApi.checkItemUsedUp(_events.SHOELACE1) || super.shellApi.checkItemUsedUp(_events.HOOK))
			{
				partDisplay.noLine.visible = false;
				partDisplay.hasLine.visible = true;
				return true
			}
			else
			{
				partDisplay.noLine.visible = true;
				partDisplay.hasLine.visible = false;
				return false;
			}
		}
	}
}