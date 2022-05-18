package game.scenes.myth.mountOlympus3.bossStates
{		
	import ash.core.Entity;
	
	import game.components.entity.Sleep;
	import game.scenes.myth.mountOlympus3.components.Bolt;
	
	/**
	 * Zeus state where he creates a ring of lightning bolts that are projected outwards. 
	 * @author umckiba
	 * 
	 */
	public class BoltsState extends ZeusState
	{		
		private const BOLT_DELAY:Number = .04;
		private var _timer:Number = 0;
		private var _boltCounter:int;
		
		public function BoltsState()
		{
			type = "bolt";
		}
		
		override public function start():void
		{
			_timer = BOLT_DELAY;
			_boltCounter = -1;
			super.updateStage = createBolts;
			super.start();
		}
		
		override public function update( time:Number ):void
		{
			super.updateStage(time);
		}
		
		private function createBolts( time:Number ):void
		{
			_timer += time;
			if( _timer >= BOLT_DELAY )
			{
				var numBolts:int = Math.floor(_timer/BOLT_DELAY);
				_timer = _timer % BOLT_DELAY;
				for (var i:int = 0; i < numBolts; i++) 
				{
					_boltCounter++;
					if( _boltCounter < node.boss.maxBolts )
					{
						var nextBolt:Entity = node.entityPool.pool.request( Bolt.BOSS_BOLT );
						if( nextBolt != null )	// bolt should be available
						{
							Sleep(nextBolt.get(Sleep)).sleeping = false;
							var bolt:Bolt = nextBolt.get(Bolt);
							bolt.state = Bolt.SPAWN;
							bolt.index = _boltCounter;
							node.boss.activeBolts++;
						}
					}
					else					// if all bolts have been activated
					{
						super.updateStage = checkBoltsComplete;
						return;
					}
				}
			}
		}
		
		private function checkBoltsComplete( time:Number ):void
		{
			if( node.boss.activeBolts == 0 )
			{
				// if no more active bolts, change boss state
				super.moveToNext();
			}
		}
	}
}