package game.scenes.prison.yard.states
{
	import flash.geom.Point;
	
	import game.scenes.prison.yard.components.Seagull;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class SeagullLandState extends MovieclipState
	{
		public function SeagullLandState()
		{
			this.type = MovieclipState.LAND;
		}
		
		override public function start():void
		{
			this.setLabel("landing");
			finishLand = false;
			
			node.motion.velocity = new Point(0,0);
			node.motion.acceleration = new Point(0,0);
			
			if(feeding)
			{
				node.spatial.scaleX = 1;
			}
			else
			{
				node.spatial.scaleX = node.entity.get(Seagull).nestDirection;
			}
		}
		
		override public function update(time:Number):void
		{
			node.motion.acceleration = new Point(0,0);
			node.motion.velocity.x = 0;
			
			if(Math.abs(node.motionTarget.targetDeltaY) < 40 && !finishLand)
			{
				finishLand = true;
				node.timeline.gotoAndPlay("ground");
				return;
			}
			
			if(node.motionTarget.targetY > node.spatial.y + 5)
			{
				node.motion.velocity.y = 85;
			}
			else
			{
				node.motion.velocity.y = 0;
				
				if(!feeding)
				{
					node.fsmControl.setState(MovieclipState.STAND);
				}
				else
				{
					node.fsmControl.setState("eating");
				}
			}
		}
		
		public var feeding:Boolean = false;
		private var finishLand:Boolean;
	}
}