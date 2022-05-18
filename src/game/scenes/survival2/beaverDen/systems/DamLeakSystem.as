package game.scenes.survival2.beaverDen.systems
{
	import ash.core.Engine;
	
	import game.scenes.myth.mountOlympus3.nodes.ZeusStateNode;
	import game.scenes.survival2.beaverDen.BeaverDen;
	import game.scenes.survival2.beaverDen.components.DamControlComponent;
	import game.scenes.survival2.beaverDen.components.LeakComponent;
	import game.scenes.survival2.beaverDen.nodes.DamControlNode;
	import game.scenes.survival2.beaverDen.nodes.LeakNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.counters.ZeroCounter;
	import org.osflash.signals.Signal;
	
	public class DamLeakSystem extends GameSystem
	{
		private var _victory:Boolean;
		private var _damControlNode:DamControlNode;
		public var complete:Signal;
		
		public function DamLeakSystem()
		{
			_victory = false;
			complete = new Signal();
			super( LeakNode, updateNode );
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			_damControlNode = systemManager.getNodeList( DamControlNode ).head as DamControlNode;
			super.addToEngine( systemManager );
		}
		
		private function updateNode( node:LeakNode, time:Number ):void
		{
			var leak:LeakComponent = node.leak;
			var damControl:DamControlComponent = _damControlNode.damControl;
			
			if( !damControl.victory && damControl.active )
			{
				if( leak.state == leak.START )
				{
					leak.leakRate = leak.START_RATE;
					node.audio.playCurrentAction( "draining" );
					node.audio.playCurrentAction( "bubbles" );
					leak.state = leak.ON;
					
					node.display.displayObject.gotoAndStop( leak.leakRate );
					leak.emitterRate = leak.emitterRateUnit * leak.leakRate;
					leak.bubbleEmitter.counter = new Random( leak.emitterRate / 2, leak.emitterRate );
				}
				else if( leak.state == leak.REPAIR )
				{
					leak.timer = 0;
					leak.state = leak.REPAIRING;
				}
				else if( leak.state == leak.REPAIRING )
				{
					leak.timer += time;
					if( leak.timer > leak.STEP_DURATION )
					{
						leak.timer = 0;
						leak.leakRate--;
						node.display.displayObject.gotoAndStop( leak.leakRate );
						if( leak.leakRate == 1 )
						{
							leak.bubbleEmitter.counter = new ZeroCounter();
							node.audio.stopActionAudio( "draining" );
							node.audio.stopActionAudio( "bubbles" );
							leak.state = leak.OFF;
							damControl.activeLeaks--;
						}
						else
						{
							leak.emitterRate = leak.emitterRateUnit * leak.leakRate;
							leak.bubbleEmitter.counter = new Random( leak.emitterRate / 2, leak.emitterRate );
						}
					}
				}
			}
			else
			{
				if( damControl.waterSpatial.y >= BeaverDen.DAM_DRAINED_Y )
				{
					node.audio.stopActionAudio( "draining" );
					node.audio.stopActionAudio( "bubbles" );
				}
			}
		}
	}
}