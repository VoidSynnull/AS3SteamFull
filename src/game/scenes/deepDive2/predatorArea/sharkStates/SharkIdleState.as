package game.scenes.deepDive2.predatorArea.sharkStates
{
	
	public class SharkIdleState extends SharkState
	{
		public function SharkIdleState()
		{
			super.type = "idle";
		}
		
		override public function start():void
		{
			this.init();
			
			if(_started){
				this.sharkTimeline.gotoAndPlay("slow");
				this.finTimeline.gotoAndPlay("slow");
				this.tailTimeline.gotoAndPlay("slow");
			} else {
				_started = true;
			}
		}
		
		override public function update(time:Number):void
		{
			if(node.shark.attackPoint){
				// attack
				node.fsmControl.setState("attack");
			} else if(node.shark.swimPoint || node.shark.targetEntity){
				// swim to
				node.fsmControl.setState("swim");
			}
		}
		
		private var _started:Boolean = false;
	}
}