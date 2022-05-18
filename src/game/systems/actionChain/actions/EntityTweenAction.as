// DUPLICATE of TweenEntityAction (use that instead)

package game.systems.actionChain.actions
{
	import com.greensock.TweenMax;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.util.TweenUtils;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// DUPLICATE of TweenEntityAction (use that instead)
	// Tween entity's component values
	public class EntityTweenAction extends ActionCommand
	{
		private var curTween:TweenMax;

		/** DUPLICATE of TweenEntityAction (use that instead)
		 * Tween entity's component values
		 * @param entityToTween			Entity to tween
		 * @param componentClass		The class of the component that we are tweening
		 * @param duration				How long the tween lasts
		 * @param vars					Array with the paramters for the tween
		 * @param name					Name given to tween
		 * @param delay					Delay before the tween commences
		 */
		public function EntityTweenAction(entityToTween:Entity, componentClass:Class, duration:Number, vars:Object, name:String = "", delay:Number = 0 ) 
		{
			curTween = TweenUtils.entityTo(entityToTween, componentClass, duration, vars, name, delay);
			curTween.pause();
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