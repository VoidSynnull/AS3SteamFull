package game.scenes.poptropolis.skiing
{
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	
	public class ObstacleObj
	{
		
		public var entity:Entity
		
		private var _timeLine:Timeline;
		
		public function ObstacleObj()
		{
		}
		
		public function init (e:Entity):void {
			entity = e
			_timeLine = e.get (Timeline)
			_timeLine.labelReached.add( onSkiingLabels );	// listen for trigger & end
		}
		
		private function onSkiingLabels (label:String):void {
			switch (label) {
				case "fallComplete":
					_timeLine.stop()
					break	
				case "stand":
					_timeLine.stop()
					break
			}
		}
		
		
	}
}