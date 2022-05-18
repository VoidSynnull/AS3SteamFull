package game.systems.actionChain.actions {

	import engine.group.Group;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Get item card
	// For any multi-action chain, you shouldn't really need this class, but it might help
	public class GetItemAction extends ActionCommand
	{
		private var itemName:String;
		private var showPopup:Boolean;

		/**
		 * Get item card
		 * @param itemName		Name of item to retrieve
		 * @param showPopup		Show popup flag (default is true)
		 */
		public function GetItemAction( itemName:String, showPopup:Boolean = true ):void
		{
			this.itemName = itemName;
			this.showPopup = showPopup;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			group.shellApi.getItem( this.itemName, null, this.showPopup );
			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
	}
}