package game.systems.actionChain.actions
{
	import com.greensock.TweenMax;
	
	import engine.group.Group;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Execute a tween
	// This action could be reproduced with some cajoling, with the CallFunctionAction, but a separate class makes everything easier to use
	// ----------CLASS USES UNMANAGED TWEENMAX INSTED OF RUNNING THROUGH OUR TWEEN COMPONENT, PLEASE USE TweenEntityAction INSTEAD----------
	public class TweenAction extends ActionCommand
	{
		private var curTween:TweenMax;

		/**
		 * Execute a tween 
		 * @param tween		Tween to execute
		 * 
		 * NOTE: tween.params.onComplete will be overridden with the actionCommand's own complete function
		 */
		public function TweenAction( tween:TweenMax ) 
		{
			tween.pause();
			this.curTween = tween;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			curTween.vars.onComplete = callback;
			curTween.play();
		}

		override public function cancel():void 
		{
			if ( this.curTween ) {
				this.curTween.kill();
			}
		}
	}
}