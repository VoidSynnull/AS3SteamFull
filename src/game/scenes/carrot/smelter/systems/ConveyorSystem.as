package game.scenes.carrot.smelter.systems
{
	import ash.core.Engine;
	
	import engine.components.Motion;
	
	import game.components.hit.Mover;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.carrot.smelter.components.Conveyor;
	import game.scenes.carrot.smelter.components.ConveyorControlComponent;
	import game.scenes.carrot.smelter.nodes.ConveyorNode;
	import game.systems.GameSystem;
	
	public class ConveyorSystem extends GameSystem
	{			
		public function ConveyorSystem( conveyorControl:ConveyorControlComponent )
		{
			_conveyorControl = conveyorControl;
			super( ConveyorNode, updateNode );
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{	
			super.addToEngine(systemManager);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function updateNode( node:ConveyorNode, time:Number ):void
		{
			var conveyor:Conveyor = node.conveyor;
							
				// gear logic
			if( conveyor.gears )
			{	
				var motion:Motion = conveyor.motion;
				if( _conveyorControl.moving )
				{
					if( motion.rotationVelocity > MAX_ROTATION )
					{
						motion.rotationVelocity -= conveyor.easing;
					}
					else
					{
						motion.rotationVelocity = MAX_ROTATION;
					}
				}
				else
				{
					if( motion.rotationVelocity < 0 )
					{
						motion.rotationVelocity += conveyor.easing;
					}
					else
					{
						motion.rotationVelocity = 0;
					}
				}
			}
			
			// belt logic
			else
			{
				var mover:Mover = conveyor.mover;
				if( _conveyorControl.moving )
				{
					if( mover.velocity.x > MAX_ROTATION )
					{
						mover.velocity.x -= conveyor.easing;
					}
					else
					{
						mover.velocity.x = MAX_ROTATION;
					}
				}
				else
				{
					if( mover.velocity.x < 0 )
					{
						mover.velocity.x += conveyor.easing;
					}
					else
					{
						mover.velocity.x = 0;
					}
				}			
			}
		}
		
		private var _conveyorControl:ConveyorControlComponent;
		private static const MAX_ROTATION:int = -250;
	}
}