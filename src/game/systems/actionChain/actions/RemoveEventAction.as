package game.systems.actionChain.actions
{
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	
	public class RemoveEventAction extends ActionCommand
	{
		private var event:String;
		private var island:String;
		public function RemoveEventAction(event:String, island:String = null)
		{
			this.event = event;
			this.island = island;
		}
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			if(group.shellApi)
			{
				group.shellApi.removeEvent(event, island);
			}
			callback();
		}
	}
}