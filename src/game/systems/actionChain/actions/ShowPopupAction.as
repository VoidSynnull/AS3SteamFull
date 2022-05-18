package game.systems.actionChain.actions
{
	import engine.group.Group;
	import engine.util.Command;
	
	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Display a standard popup
	public class ShowPopupAction extends ActionCommand
	{
		private var popup:Popup;
		private var overrideInputLock:Boolean;
		
		/**
		 * Display a standard popup 
		 * @param popup					Popup to display
		 * @param overrideInputLock		Override input lock flag (default is true)
		 */
		public function ShowPopupAction(popup:Popup, overrideInputLock:Boolean = true)
		{
			this.popup = popup;
			this.overrideInputLock = overrideInputLock;
			super();
		}

		override public function preExecute(callback:Function, group:Group, node:SpecialAbilityNode = null):void
		{
			group.addChildGroup(popup);
			popup.popupRemoved.addOnce(callback);
			
			if(overrideInputLock)
			{
				SceneUtil.lockInput(group, false);
				popup.popupRemoved.addOnce(Command.create(SceneUtil.lockInput, group, true));
			}
		}
	}
}