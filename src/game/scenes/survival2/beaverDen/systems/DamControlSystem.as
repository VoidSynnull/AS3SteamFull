package game.scenes.survival2.beaverDen.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.components.hit.EntityIdList;
	import game.scenes.survival2.beaverDen.BeaverDen;
	import game.scenes.survival2.beaverDen.components.DamControlComponent;
	import game.scenes.survival2.beaverDen.components.LeakComponent;
	import game.scenes.survival2.beaverDen.nodes.DamControlNode;
	import game.scenes.survival2.beaverDen.nodes.LeakNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class DamControlSystem extends GameSystem
	{
		public var hit:Signal;
		public var drainRate:Number = 3;	//pixels per second
		public var fillRate:Number = 8;		//pixels per second
		private var _leakList:NodeList;
		
		public function DamControlSystem()
		{
			hit = new Signal();
			super( DamControlNode, updateNode );
			super._defaultPriority = SystemPriorities.resolveCollisions;
			super.fixedTimestep = 1/10;	// only need to update every second
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			_leakList = systemManager.getNodeList( LeakNode );
			super.addToEngine( systemManager );
		}
		
		private function updateNode( node:DamControlNode, time:Number ):void
		{
			var number:int;
			var leak:LeakComponent;
			var leakNode:LeakNode
			var damControl:DamControlComponent = node.damControl
			
			if( !damControl.victory )		// if water has not reached 'win' level
			{
				// determine if holes can be open/reopened when character lands on dam
				var entityList:EntityIdList = node.entityList;
				if( entityList.hasEntities && !entityList.presentFlag  )
				{
					// reset leaks if they are all off
					if( damControl.activeLeaks == 0 )
					{
						for( leakNode = _leakList.head; leakNode; leakNode = leakNode.next )
						{
							leak = leakNode.leak;
							if( !damControl.active )	{ damControl.active  = true; }
							damControl.activeLeaks ++;
							leak.state = leak.START;
						}
						hit.dispatch();
					}
					entityList.presentFlag = true;
				}
				else
				{
					entityList.presentFlag = false;
				}
				 
				if( damControl.activeLeaks > 0 )		// if leaks are active drain water
				{
					damControl.waterSpatial.y += time * drainRate;
					// update particle death zone 
					for( leakNode = _leakList.head; leakNode; leakNode = leakNode.next )
					{
						leak = leakNode.leak;
						if( leak.deathZone.zone == null )
						{
							leak.deathZone.zone = new RectangleZone( -40, damControl.waterSpatial.y - 1220, 40, 40 );
						}
						else
						{
							RectangleZone(leak.deathZone.zone).top = damControl.waterSpatial.y - 1220;
						}
					} 
				}
				else								//if leaks are closed fill water
				{
					if( damControl.waterSpatial.y > 1028 )	// while has reached top
					{
						damControl.waterSpatial.y -= time * fillRate;	// TODO :: limit to frequency of redraw. - Bard
						// update particle death zone 
						for( leakNode = _leakList.head; leakNode; leakNode = leakNode.next )
						{
							leak = leakNode.leak;
							if( leak.deathZone.zone == null )
							{
								leak.deathZone.zone = new RectangleZone( -40, damControl.waterSpatial.y - 1220, 40, 40 );
							}
							else
							{
								RectangleZone(leak.deathZone.zone).top = damControl.waterSpatial.y - 1220;
							}
						} 
					}
				}
			}
			else if( damControl.active ) 
			{
				if( damControl.waterSpatial.y < BeaverDen.DAM_DRAINED_Y )	
				{
					damControl.waterSpatial.y += time * drainRate * 2;	// increase drain speed once won // TODO :: limit to frequency of redraw. - Bard

					for( leakNode = _leakList.head; leakNode; leakNode = leakNode.next )
					{
						leak = leakNode.leak;
						leak.deathZone.zone = new RectangleZone( -40, damControl.waterSpatial.y - 1220, 40, 40 );
					}
				}
			}
		}
	}
}