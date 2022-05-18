package com.poptropica.shellSteps.shared
{
	import game.managers.ItemManager;
	import game.managers.ProfileManager;
	import game.managers.interfaces.IItemManager;
	import game.scene.template.ui.CardGroup;

	public class RestoreGlobalItems extends ShellStep
	{
		public function RestoreGlobalItems()
		{
			super();
			stepDescription = "Restoring inventory";
		}
		
		override protected function build():void
		{
			// NOTE :: only need to restore global items ( store, campaign ) on start up.
			// Island specifc items are restore on island entry by IslandManager
			restoreGlobalItemsFromProfile();
			super.built();
		}
		
		public function restoreGlobalItemsFromProfile():void 
		{
			// restore items from profile (profile should of already been updated with items at this point)
			var profileManager:ProfileManager = shellApi.getManager( ProfileManager ) as ProfileManager;
			var itemManager:ItemManager  = shellApi.getManager(IItemManager) as ItemManager;
			
			if (profileManager.active.items) {
				if (profileManager.active.items[CardGroup.STORE]) {
					itemManager.restoreSets(profileManager.active.items, CardGroup.STORE);
				}
				if (profileManager.active.items[CardGroup.PETS]) {
					itemManager.restoreSets(profileManager.active.items, CardGroup.PETS);
				}
				if (profileManager.active.items[CardGroup.CUSTOM]) {
					itemManager.restoreSets(profileManager.active.items, CardGroup.CUSTOM);
				}
			}
		}		
	}
}