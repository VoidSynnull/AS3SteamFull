package game.systems.actionChain.actions 
{
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.ItemGroup;
	import game.systems.actionChain.ActionCommand;

	// Remove item card
	public class RemoveItemAction extends ActionCommand
	{
		public var itemName:String;
		public var showPopup:Boolean;
		public var removeEvent:Boolean;
		public var item_taker:String;

		/**
		 * Remove item card 
		 * @param itemName		Name of item card to remove
		 * @param item_taker	ID of npc entity that is taking the item
		 * @param showPopup		Show popup flag
		 */
		public function RemoveItemAction( itemName:String, item_taker:String, showPopup:Boolean = true, removeEvent:Boolean = true ) 
		{
			this.itemName = itemName;
			this.showPopup = showPopup;
			this.removeEvent = removeEvent;
			this.item_taker = item_taker;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			if(removeEvent){
				group.shellApi.removeItem( this.itemName );
			}
			if ( this.showPopup ) 
			{
				var itemGroup:ItemGroup = group.getGroupById( "itemGroup" ) as ItemGroup;
				itemGroup.takeItem( this.itemName, this.item_taker );
			}
			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
	}
}