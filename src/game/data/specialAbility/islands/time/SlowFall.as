// Used by:
// Card "ability_glider" on time island using item glider

package game.data.specialAbility.islands.time
{
	
	import engine.components.Motion;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	
	/**
	 * Slow falling speed for things like the DaVinci glider
	 * 
	 * Optional params:
	 * gravityDampening		Number		Gravity dampening (default is -1000)
	 */
	public class SlowFall extends SpecialAbility
	{		
		override public function activate( node:SpecialAbilityNode ):void
		{
			_charMotion = CharacterMotionControl( node.entity.get(CharacterMotionControl));
			super.data.isActive = true;
		}
		
		override public function update( node:SpecialAbilityNode, time:Number ):void
		{
			if (super.data.isActive)
			{
				//only works on time tangled island
				var charState:String = CharUtils.getStateType( super.entity );
				var motion:Motion = Motion( super.entity.get(Motion));
				
				// if jumping or falling, turn of spin and adjust gravity
				if( (charState == CharacterState.JUMP) || (charState == CharacterState.FALL) )
				{
					_charMotion.spinEnd = true;
					if(motion.velocity.y > 0)
					{
						_charMotion.gravity =  MotionUtils.GRAVITY + _gravityDampening;
					}else{
						_charMotion.gravity =  MotionUtils.GRAVITY;
					}
				}
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.data.isActive = false;
			if( _charMotion )
				_charMotion.gravity = MotionUtils.GRAVITY;
		}
		
		public var _gravityDampening:Number = -1000;
		
		private var _charMotion:CharacterMotionControl;
	};
}
