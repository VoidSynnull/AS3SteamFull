package game.creators.entity.horse.states
{	

	import game.systems.entity.character.clipChar.MovieclipState;
	
	
	public class HorseJumpState extends MovieclipState
	{
		public function HorseJumpState()
		{
			super.type = MovieclipState.JUMP;
		}
		
		override public function start():void
		{
			// set anim
			super.setLabel("jump2",true);
		}
		
		override public function update( time:Number ):void
		{
			if(!node.motionControl.inputStateDown){
				node.fsmControl.setState(MovieclipState.STAND);
			}else{
				
			}
		}
	}
}