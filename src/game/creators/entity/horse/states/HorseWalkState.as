package game.creators.entity.horse.states
{	

	import game.systems.entity.character.clipChar.MovieclipState;

	
	public class HorseWalkState extends MovieclipState
	{
		public function HorseWalkState()
		{
			super.type = MovieclipState.WALK;
		}
		
		override public function start():void
		{
			// set anim
			super.setLabel("walk",true);
		}
		
		override public function update( time:Number ):void
		{
			if(node.motionControl.inputStateDown){
				
			}else{
				node.fsmControl.setState(MovieclipState.STAND);
			}
		}
	}
}