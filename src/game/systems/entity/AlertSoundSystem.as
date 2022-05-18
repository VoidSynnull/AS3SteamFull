package game.systems.entity
{
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.AlertSoundNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;
	
	public class AlertSoundSystem extends GameSystem
	{
		public function AlertSoundSystem()
		{
			super( AlertSoundNode, updateNode );
			super._defaultPriority = SystemPriorities.moveComplete;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			
			triggered = new Signal();
			reset = new Signal();
		}
		
		private function updateNode( node:AlertSoundNode, time:Number ):void
		{
			if( node.entityList.entities.length > 0 )
			{
				if( !node.alert.checkReset )
				{
					triggered.dispatch();
				}
				
				else if( node.alert.active )
				{	
					triggered.dispatch();
					node.alert.active = false;
				}
			}
			
			else if( node.alert.checkReset )
			{
				node.alert.active = true;
				reset.dispatch();
			}
		}
		
		public var triggered:Signal;
		public var reset:Signal;
	}
}