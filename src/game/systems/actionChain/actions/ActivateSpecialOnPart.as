package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.entity.character.part.MetaPart;
	import game.data.character.part.PartMetaData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;
	
	public class ActivateSpecialOnPart extends ActionCommand
	{
		public function ActivateSpecialOnPart(char:Entity, partType:String)
		{
			_part = CharUtils.getPart(char, partType);
		}
		
		override public function preExecute(_pcallback:Function, group:Group, node:SpecialAbilityNode=null):void
		{
			if(_part)
			{
				var metaPart:MetaPart = _part.get(MetaPart);
				if(metaPart)
				{
					if(metaPart.currentData.special.specialAbility)
					{
						metaPart.currentData.special.specialAbility.activate(node);
						_pcallback();
						return;
					}
				}
			}
			
			trace("ActivateSpecialOnPart:: Couldn't find a part or special ability, therefore no action");
			_pcallback();
		}
		
		private var _part:Entity;
	}
}