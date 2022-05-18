// Used by:
// Card 3013 using item pLion
// Card 3035 and 3036 using item pBaseball
// Card 3084 using item ptigerShark
// Card 3092 using item football
// Card 3130 and 3131 using item phammershark
// Card 3361 using item psoccerball

package game.data.specialAbility.character
{
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.specialAbility.character.Toss;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Tossup;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.specialAbility.character.TossSystem;
	import game.util.CharUtils;
	
	/**
	 * Avatar tosses item up into air using Toss animation
	 */
	public class TossItem extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{	
			// Add the Toss Sytem if it's not there already
			if( !super.group.getSystem( TossSystem ) )
			{
				var tossSystem:TossSystem = new TossSystem();
				super.group.addSystem( tossSystem );
			}
			
			if ( !super.data.isActive )
			{
				var currentState:String = CharUtils.getStateType(entity)
				if(currentState == CharacterState.STAND || currentState == CharacterState.CLIMB)
				{
					super.setActive( true );
					CharUtils.lockControls( super.entity, true, false );
					CharUtils.setAnim( super.entity, Tossup );
					CharUtils.getTimeline( super.entity ).handleLabel( Animation.LABEL_ENDING, completed );
					CharUtils.getTimeline( super.entity ).handleLabel("trigger", doToss);
				}
			}
		}
		
		/**
		 * Toss item when animation reaches trigger
		 */
		private function doToss():void
		{
			var partEntity:Entity = CharUtils.getPart(super.entity, "item");
			var partspatial:Spatial = partEntity.get(Spatial);
			
			objectEntity = new Entity();
			objectEntity.add(new Display(partEntity.get(Display).displayObject));
			objectEntity.add(new Spatial(partspatial.x, partspatial.y));
			objectEntity.add(new Toss(partEntity, super.entity));
			super.group.addEntity(objectEntity);
		}
		
		/**
		 * When animation ends 
		 */
		private function completed():void
		{
			super.setActive( false );
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
			
			objectEntity.remove(Toss);
		}
		
		private var objectEntity:Entity;
	}
}