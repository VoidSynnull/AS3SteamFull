package game.systems.actionChain.actions
{
	import com.greensock.TweenMax;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.TweenUtils;

	// Tween entity's component values
	// Use this instead of TweenAction whereever possible
	public class TweenEntityAction extends ActionCommand
	{
		private var curTween:TweenMax;
		private var entity:Entity;
		private var component:Class;
		private var duration:Number;
		private var vars:Object;
		private var name:String;
		private var delay:Number;
		
		/**
		 * Tween entity's component values 
		 * @param entityToTween			Entity to tween
		 * @param componentClass		The class of the component that we are tweening
		 * @param duration				How long the tween lasts
		 * @param vars					Array with the paramters for the tween
		 * @param name					Name given to tween
		 * @param delay					Delay before the tween commences
		 */
		public function TweenEntityAction( entityToTween:Entity, componentClass:Class, duration:Number, vars:Object, name:String = "", delay:Number = 0 ) 
		{
			this.entity = entityToTween;
			this.component = componentClass;
			this.duration = duration;
			this.vars = vars;
			this.name = name;
			this.delay = delay;
		}
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			curTween = TweenUtils.entityTo(entity, component, duration, vars, name, delay);
			curTween.vars.onComplete = callback;
		}
		
		override public function cancel():void 
		{
			if ( this.curTween ) 
			{
				this.curTween.kill();
			}
		}
	}
}