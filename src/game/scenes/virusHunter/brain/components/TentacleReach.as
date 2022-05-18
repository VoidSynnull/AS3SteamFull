package game.scenes.virusHunter.brain.components
{
	import flash.display.DisplayObject;
	
	public class TentacleReach extends IKReach
	{
		public function TentacleReach($segmentPrefix:String, $display:DisplayObject, $segWidth:Number, $startAtInt:int = 0)
		{
			super($segmentPrefix, $display, $segWidth, $startAtInt);
		}
	}
}