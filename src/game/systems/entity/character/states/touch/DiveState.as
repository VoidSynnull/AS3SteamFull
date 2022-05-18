package game.systems.entity.character.states.touch 
{
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.DiveState;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class DiveState extends game.systems.entity.character.states.DiveState 
	{
		private var _directionXFactor:Number = 0;
		protected const ROTATION_OFFSET:int = 30;
		
		public function DiveState()
		{
			super.type = CharacterState.DIVE;
		}
		
		override public function start():void
		{
			_directionXFactor = 0;
			super.start();
		}
	}
}