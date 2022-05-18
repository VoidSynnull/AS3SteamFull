// Used by:
// Card "mittens" on survival1 island

package game.data.specialAbility.islands.survival 
{
	import ash.core.Entity;
	
	import game.components.entity.character.part.item.ItemMotion;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.SkinUtils;

	/*
	 * This class sets up any part as a Timeline animation and lets you play
	 * the animation when the Special Ability is activated
	 * 
	 * params:
		* Param1 = name of part value to for hand (or just hand front if 2 parameters are given)
		* Param2 = name of part value to for hand back
	 *
	 * To add this ability ot a card xml use the following format:
	 *
		<specialAbilities>
			<specialAbility id="SetHands">
				<className>game.data.specialAbility.character.SetHandParts</className>
				<parameters>
					<param id="front">mitten_front</param>
					<param id="back">mitten_back</param>
				</parameters>
			</specialAbility>
		</specialAbilities>
	 *
	 */
	public class SetHandParts extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			_handFrontValue = String(super.data.params.byId(FRONT_ID));
			_handBackValue = String(super.data.params.byId(BACK_ID));
			var handEntity:Entity;
			var itemMotion:ItemMotion;
			
			if( _handFrontValue )
			{
				handEntity = CharUtils.getPart( node.entity, CharUtils.HAND_FRONT );
				if( handEntity )
				{
					itemMotion = new ItemMotion();
					itemMotion.isFront = true;
					handEntity.add( itemMotion );
					SkinUtils.setSkinPart( node.entity, CharUtils.HAND_FRONT, _handFrontValue );
				}
			}
			
			if( _handBackValue )
			{
				handEntity = CharUtils.getPart( node.entity, CharUtils.HAND_BACK );
				if( handEntity )
				{
					itemMotion = new ItemMotion();
					itemMotion.isFront = false;
					handEntity.add( itemMotion );
					SkinUtils.setSkinPart( node.entity, CharUtils.HAND_BACK, _handBackValue );
				}
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			var handEntity:Entity
			
			if( _handFrontValue )
			{
				handEntity = CharUtils.getPart( node.entity, CharUtils.HAND_FRONT );
				if( handEntity )
				{
					handEntity.remove( ItemMotion );
					SkinUtils.setSkinPart( node.entity, CharUtils.HAND_FRONT, DEFAULT_VALUE );
				}
			}
			
			if( _handBackValue )
			{
				handEntity = CharUtils.getPart( node.entity, CharUtils.HAND_BACK );
				if( handEntity )
				{
					handEntity.remove( ItemMotion );
					SkinUtils.setSkinPart( node.entity, CharUtils.HAND_BACK, DEFAULT_VALUE );
				}
			}
		}
		
		public var _handFrontValue:String;
		public var _handBackValue:String;
		
		private const FRONT_ID:String = "front";
		private const BACK_ID:String = "back";
		private const DEFAULT_VALUE:String = "hand";
	}
}