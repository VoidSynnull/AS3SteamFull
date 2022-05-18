package game.scenes.gameJam.dancingZombie.systems
{
	import ash.core.Node;
	
	import game.scenes.gameJam.dancingZombie.nodes.BeatDrivenNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;

	public class BeatDriverSystem extends GameSystem
	{
		private var _totalTime:Number = 0;
		private var _currentDuration:Number = 0;	//seconds
		private var _currentMeasure:int = 0;
		private var _beatHit:Boolean = false;
		private var _beatMeasure:int = 4;
		public var _beatHitFlag:Boolean = false;
		
		private var _latencyAverageTries:int = 0;
		private var _latencyAverageTotal:Number = 0;
		//private var _latencyMin:Number = 
		
		// set externally by group adding creating system
		public var beatLength:Number = 0; // seconds
		public var beatWindow:Number = 0; // seconds
		public var beatLatency:Number = 0;
		public var onBeat:Signal;

		public function start():void { _started = true; }
		private var _started:Boolean = false;
		
		public function BeatDriverSystem()
		{
			super( BeatDrivenNode, updateNode );
			super._defaultPriority = SystemPriorities.update;
			onBeat = new Signal();
		}
		
		/*
		private function nodeAdded(node:BeatDrivenNode):void
		{
			node.beatDriven.measure = _currentMeasure;
			node.beatDriven.beatHit = _beatHit;
			super.nodeAddedFunction()
		}
		*/
		
		override public function update(time:Number):void
		{
			if( _started )
			{
				// update time 
				_currentDuration += time;
				_beatHit = false;
				
				//determine is on beat
				if( _currentDuration > beatLength )
				{
					_beatHit = true;
					_beatHitFlag = false;
					onBeat.dispatch();
					//trace ( "Beat Hit");
					_currentDuration -= beatLength;
					_currentMeasure++;
					if( _currentMeasure > _beatMeasure )
					{
						_currentMeasure = 1;
					}
				}
				
				for( var node:Node = super.nodeList.head; node; node = node.next )
				{
					if (!EntityUtils.sleeping(node.entity))
					{
						nodeUpdateFunction(node, time);
					}
				}
			}
		}
		
		private function updateNode(node:BeatDrivenNode, time:Number):void
		{
			node.beatDriven.measure = _currentMeasure;
			node.beatDriven.beatHit = _beatHit;
		}
		
		// can be called at anytime, check system to see if click has happened within beat window
		public function inBeatRange():Boolean
		{
			if( !_beatHitFlag )
			{
				var difference:Number = _currentDuration - beatLength;
				updateBeatLatency( difference );
				trace ( this," :: inBeatRange : currentDuration:",_currentDuration,"difference:",difference,"latency:",beatLatency,"beatWindow:",beatWindow );
				if( Math.abs(_currentDuration + beatLatency - beatLength ) < beatWindow )
				{
					_beatHitFlag = true;
					trace( "Beat HIT" );
					return true;
				}
			}
			trace( "Beat MISSED" );
			return false;
		}
		
		private function updateBeatLatency( difference:Number ):void
		{
			_latencyAverageTries++;
			_latencyAverageTotal += difference;
			if( _latencyAverageTries > 5 )
			{
				//TODO :: Don;t want to be constantly avergaing, once we feel we have a good sense of the latency, we should lock it and stop adjusting
				beatLatency = Math.abs(_latencyAverageTotal/_latencyAverageTries);
			}
		}
	}
}