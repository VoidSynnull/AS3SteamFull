package game.systems.actionChain.actions
{
	import engine.group.Group;
	
	import game.systems.actionChain.ActionCommand;
	import game.util.ColorUtil;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Apply screen tint to scene
	public class ScreenTintAction extends ActionCommand
	{
		private var color:uint;
		private var percent:Number;
		
		/**
		 * Apply screen tint to scene 
		 * @param color		Color of tint
		 * @param percent	Alpha value of tint
		 */
		public function ScreenTintAction(color:uint, percent:Number)
		{
			this.color = color;
			this.percent = percent;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			ColorUtil.tint(group.shellApi.screenManager.container, color, percent);
			callback();
		}
		
		override public function revert( group:Group ):void
		{
			// set to clear tint
			ColorUtil.tint(group.shellApi.screenManager.container, 0xFFFFFF, 0);
		}
	}
}