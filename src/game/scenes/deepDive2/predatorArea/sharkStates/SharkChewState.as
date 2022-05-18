package game.scenes.deepDive2.predatorArea.sharkStates
{
	
	public class SharkChewState extends SharkState
	{
		public function SharkChewState()
		{
			super.type = "chew";
		}
		
		override public function start():void
		{
			this.init();
			
			this.sharkTimeline.gotoAndPlay("slow");
			this.finTimeline.gotoAndPlay("slow");
			this.tailTimeline.gotoAndPlay("slow");
			
			node.motion.zeroAcceleration();
			node.motion.zeroMotion();
			
			_c = 0;
		}
		
		override public function update(time:Number):void
		{
			_c++;
			if(_c >= 60){
				node.fsmControl.setState("idle");
			}
		}
		
		private var _c:int;;
	}
}