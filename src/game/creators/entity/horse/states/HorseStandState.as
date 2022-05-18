package game.creators.entity.horse.states
{

	import ash.core.Entity;
	
	import engine.components.Spatial;

	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.GeomUtils;
	
	public class HorseStandState extends MovieclipState
	{
		public function HorseStandState()
		{
			super.type = MovieclipState.STAND;
		}
		
		override public function start():void
		{
			//set anim
			super.setLabel("stand",true);
			var input:Entity = node.entity.group.shellApi.inputEntity;
			node.motionTarget.targetSpatial = input.get(Spatial);
		}
		
		override public function update( time:Number ):void
		{
			if(node.motionControl.inputStateDown){
				var deg:Number = GeomUtils.degreesBetween( node.entity.group.shellApi.offsetX(node.motion.x), node.entity.group.shellApi.offsetY(node.motion.y), node.motionTarget.targetX, node.motionTarget.targetY );
				if(deg < 40 || deg > 140){
					node.fsmControl.setState(MovieclipState.WALK);
				}else{
					node.fsmControl.setState(MovieclipState.JUMP);
				}
			}
		}
	}
}