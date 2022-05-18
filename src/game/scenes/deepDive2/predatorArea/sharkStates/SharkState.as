package game.scenes.deepDive2.predatorArea.sharkStates
{
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.scenes.deepDive2.predatorArea.nodes.SharkNode;
	import game.systems.animation.FSMState;
	import game.util.TimelineUtils;
	
	public class SharkState extends FSMState
	{
		public function SharkState()
		{
			super();
		}
		
		protected function init():void{
			if(!sharkTimeline){
				
				var shark:Entity = TimelineUtils.getChildClip(node.entity, "shark");
				
				sharkTimeline = shark.get(Timeline);
				var fin:Entity = TimelineUtils.getChildClip(shark, "fin");
				finTimeline = fin.get(Timeline);
				var tail:Entity = TimelineUtils.getChildClip(shark, "tail");
				tailTimeline = tail.get(Timeline);
				var head:Entity = TimelineUtils.getChildClip(shark, "head");
				headTimeline = head.get(Timeline);
			}
		}
		
		protected function orientShark():void{
			//trace(node.spatial.rotation);
			if(node.spatial.rotation >= 90 || node.spatial.rotation <= -90){
				node.spatial.scaleY = -1;
			} else {
				node.spatial.scaleY = 1;
			}
		}
		
		public function get node():SharkNode{ return this._node as SharkNode }
		
		protected var sharkTimeline:Timeline;
		protected var finTimeline:Timeline;
		protected var tailTimeline:Timeline;
		protected var headTimeline:Timeline;
		
	}
}