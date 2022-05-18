// Used by:
// Card "wrench" on hub island using item wrench
// Cards 3046 and 3047 using item pbowstaff
// Cards 3061 and 3062 using item pdevil
// Card 3112 using item pskullpirate1
// Card 3117 using item ppromking1a, ppromking1b, ppromking1c, ppromking1d
// Cards 3180 and 3181 using item plawman
// Card 3184 using item sai
// Card 3368 using item pitchfork

package game.data.specialAbility.character
{
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.entity.character.part.item.ItemMotion;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Twirl;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	/**
	 * Twirl item in hand using Twirl animation and ItemMotion.setSpin()
	 * 
	 * Optional params:
	 * spinSpeed		Number		Item spin speed (default is 20)
	 * spinNum			Number		Number of times to spin (default is 3)
	 */
	public class TwirlItem extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{	
			if ( !super.data.isActive )
			{
				CharUtils.lockControls(entity, true, false);
				super.setActive(true);
				CharUtils.setAnim(entity, _animation);
				CharUtils.getTimeline(entity).handleLabel(Animation.LABEL_ENDING, completed);
				
				var partEntity:Entity = CharUtils.getPart(entity, SkinUtils.ITEM);
				if( partEntity )
				{
					var itemMotion:ItemMotion = partEntity.get(ItemMotion);
					if( itemMotion != null )
					{
						_hadItemMotion = true;
						_itemMotionPreviousState = itemMotion.state;
					}
					else
					{
						itemMotion = new ItemMotion();
						partEntity.add( itemMotion );
					}
					
					if(!_animationWait)
					{
						setSpin(itemMotion);						
					}
					else
					{
						CharUtils.getTimeline(entity).handleLabel(_animationWait, Command.create(setSpin, itemMotion));
					}
				}
			}
		}
		
		private function setSpin(itemMotion:ItemMotion):void
		{
			itemMotion.state = ItemMotion.SPIN;
			itemMotion.setSpin( _spinNum, _spinSpeed, _spinForward );
		}
		
		/**
		 * When animation completed
		 */
		private function completed():void
		{
			super.setActive( false );
			
			var partEntity:Entity = CharUtils.getPart(super.entity, SkinUtils.ITEM);
			if( partEntity )
			{
				var itemMotion:ItemMotion = partEntity.get(ItemMotion);
				if( _hadItemMotion )
					itemMotion.state = _itemMotionPreviousState;
				else
					partEntity.remove( ItemMotion );
			}
				
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
		}
		
		public var _animation:Class = Twirl;
		public var _animationWait:String;
		public var _spinSpeed:Number = 20;
		public var _spinNum:Number = 3;
		public var _spinForward:Boolean = true;

		private var _hadItemMotion:Boolean = false;
		private var _itemMotionPreviousState:String;
	}
}