package game.systems.actionChain.actions
{
	import engine.group.Group;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Trigger event
	public class TriggerEventAction extends ActionCommand
	{
		private var event:String;
		private var save:Boolean;
		private var makeCurrent:Boolean;
		private var island:String;
		
		/**
		 * Trigger event 
		 * @param event			Event to trigger
		 * @param save			Save flag
		 * @param makeCurrent	Make current event flag
		 * @param island		island name
		 */
		public function TriggerEventAction(event:String, save:Boolean = false, makeCurrent:Boolean = true, island:String = null)
		{
			this.event = event;
			this.save = save;
			this.makeCurrent = makeCurrent;
			this.island = island;
			super();
		}
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			if(group.shellApi)
			{
				group.shellApi.triggerEvent(this.event, this.save,this.makeCurrent, this.island);
			}
			callback();
		}
	}
}