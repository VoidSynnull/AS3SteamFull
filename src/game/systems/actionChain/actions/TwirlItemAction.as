package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.character.part.item.ItemMotion;
	import game.data.animation.Animation;
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Twirl item in avatar's hand
	public class TwirlItemAction extends ActionCommand
	{
		private var animClass:Class;
		private var speed:Number;
		private var acceleration:Number;
		private var reverseAtTrigger:Boolean;
		private var reverseRotation:Number;
		private var reverseAccel:Number;
		
		private var _hadItemMotion:Boolean = false;
		private var _partEntity:Entity;
		private var _partSpatial:Spatial;
		private var _callback:Function;

		/**
		 * Twirl item in avatar's hand 
		 * @param char					Char entity
		 * @param animClass				Animation class
		 * @param speed					Rotational speed
		 * @param acceleration			Rotational acceleration
		 * @param reverseAtTrigger		Reverse rotational acceleration at trigger frame in animation
		 * @param reverseRotation		Rotation value of item when reach trigger
		 * @param reverseAccel			New acceleration when reach trigger
		 */
		public function TwirlItemAction( char:Entity, animClass:Class, speed:Number = 10, acceleration:Number = 0.1, reverseAtTrigger:Boolean = true, reverseRotation:Number = 120, reverseAccel:Number = -1 )
		{
			entity = char;
			this.animClass = animClass;
			this.speed = speed;
			this.acceleration = acceleration;
			this.reverseAtTrigger = reverseAtTrigger;
			this.reverseRotation = reverseRotation;
			this.reverseAccel = reverseAccel;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			_callback = callback;
			
			if (entity == null)
				return;

			// get item part
			_partEntity = CharUtils.getPart(entity, SkinUtils.ITEM);
			
			// if found
			if( _partEntity )
			{
				// set update function
				this.update = this.twirlItem;
				
				// check if has ItemMotion
				if( _partEntity.get(ItemMotion) )
				{
					_hadItemMotion = true;
					// remove item motion
					_partEntity.remove(ItemMotion);
				}
				// get spatial
				_partSpatial = _partEntity.get(Spatial);
			}
			
			// start animation
			CharUtils.lockControls( entity, true, false );
			CharUtils.setAnim( entity, animClass );
			
			// if reversing motion, then listen for trigger
			if (reverseAtTrigger)
				CharUtils.getTimeline( entity ).handleLabel( "trigger", reverseSpin );
			
			// when animation is over
			CharUtils.getTimeline( entity ).handleLabel( Animation.LABEL_ENDING, endAnim );
		}
		
		/**
		 * Twirl item by updating spatial 
		 * @param time
		 * 
		 */
		public function twirlItem( time:Number ):void
		{
			speed = speed + acceleration;
			
			// if reversing or speed is still positive (not reversing) then set rotation
			if( (reverseAtTrigger) || (speed > 0) )
				_partSpatial.rotation -= speed;
		}
		
		/**
		 * Reverse direction of spin 
		 */
		private function reverseSpin():void
		{
			if (_partSpatial)
			{
				_partSpatial.rotation = reverseRotation;
				acceleration = reverseAccel;
			}
		}
		
		/**
		 * When animation done 
		 */
		private function endAnim():void
		{
			// restore item motion if part and had item motion
			if ((_partEntity) && (_hadItemMotion))
				_partEntity.add(new ItemMotion());
			
			// restore avatar
			CharUtils.stateDrivenOn( entity );
			CharUtils.lockControls( entity, false, false );
			
			this.update = null;
			
			// callback
			_callback();
		}
	}
}