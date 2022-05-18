package game.scenes.carrot.smelter.systems
{
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.data.motion.time.FixedTimestep;
	import game.managers.EntityPool;
	import game.scenes.carrot.smelter.components.ConveyorControlComponent;
	import game.scenes.carrot.smelter.components.PressedLeadComponent;
	import game.scenes.carrot.smelter.nodes.PressedLeadNode;
	import game.systems.GameSystem;
	
	public class PressedLeadSystem extends GameSystem
	{
		public function PressedLeadSystem( conveyorControl:ConveyorControlComponent, pool:EntityPool, total:Dictionary )
		{
			_conveyorControl = conveyorControl;
			_pool = pool;
			_total = total;
			super( PressedLeadNode, updateNode );
		}

		override public function addToEngine( systemsManager:Engine ):void
		{	
			super.addToEngine(systemManager);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function updateNode( node:PressedLeadNode, time:Number ):void
		{
			var motion:Motion = node.motion;
			var lead:PressedLeadComponent = node.lead;
//			var spatial:Spatial = node.spatial;
			var sleep:Sleep = node.sleep;
			var type:String = OUTTER;
			
			if( _conveyorControl.moving )
			{
				if( motion.velocity.x > MOVER_SPEED )
				{
					motion.velocity.x -= EASING;
				}
				
				else
				{
					motion.velocity.x = MOVER_SPEED;
				}
			}
			
			else  // if paused
			{
				if( motion.x < 0 )
				{
					motion.velocity.x += EASING;
				}
				
				else
				{
					motion.velocity.x = 0;
				}
			}
			
			if( motion.x < 0 )
			{
				sleep.sleeping = true;				
				
				if( lead.innerSide )
				{
					type = INNER;
				}
				if( _pool.release( node.entity, type ))
				{
					_total[ type ]--;
				}
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( PressedLeadNode );
			super.removeFromEngine( systemManager );
		}
		
		private var _pool:EntityPool;
		private var _total:Dictionary;
		
		public static const EASING:uint = 25;
		public static const MOVER_SPEED:int = -250;

		private static const INNER:String = "leadInner";
		private static const OUTTER:String =	"leadOutter";
		private var _conveyorControl:ConveyorControlComponent;
	}
}