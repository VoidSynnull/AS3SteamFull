package game.systems.entity.character.states.movieClip
{
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.systems.animation.FSMState;
	import game.util.TimelineUtils;
	
	public class MCState extends FSMState
	{
		public function MCState()
		{
			super();
		}
		
		public function get node():MCStateNode
		{
			return MCStateNode(this._node);
		}
		
		protected function setLabel(label:String, play:Boolean = true):void
		{
			if(play)
				node.timeline.gotoAndPlay(label);
			else
				node.timeline.gotoAndStop(label);
		}
		
		protected function setChildLabel(child:String, label:String, play:Boolean = true):void
		{
			var childEntity:Entity = TimelineUtils.getChildClip(node.entity, child);
			
			try
			{
				var timeline:Timeline = childEntity.get(Timeline);
				if(play) timeline.gotoAndPlay(label);
				else timeline.gotoAndStop(label);
			} 
			catch(error:Error) 
			{
				trace("MovieclipState at: "+child+" ... Couldn't find a timeline on the child entity.");
			}			
		}
		
		public function directionByVelocity():void
		{
			if ( node.motion.velocity.x > 0 )
			{
				node.spatial.scaleX = -node.spatial.scale;
			}
			else if( node.motion.velocity.x < 0 )
			{
				node.spatial.scaleX = node.spatial.scale;
			}
		}
	}
}