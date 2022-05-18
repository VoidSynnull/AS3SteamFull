package game.systems.entity.character.clipChar
{
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.nodes.entity.character.clipChar.MovieclipStateNode;
	import game.systems.animation.FSMState;
	import game.util.TimelineUtils;
	
	/**
	 * @author Scott Wszalek
	 */
	public class MovieclipState extends FSMState
	{
		public function MovieclipState()
		{
		}
		
		public function get node():MovieclipStateNode
		{
			return MovieclipStateNode(super._node);
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
		
		/**
		 * Update facing direction by velocity
		 * @param	node
		 * @return
		 */
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
		
		public static const STAND:String = "stand";
		public static const RUN:String = "run";
		public static const JUMP:String = "jump";
		public static const WALK:String = "walk";
		public static const LAND:String = "land";
	}
}