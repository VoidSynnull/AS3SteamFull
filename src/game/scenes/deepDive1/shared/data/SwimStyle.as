package game.scenes.deepDive1.shared.data
{	
	import game.scenes.deepDive1.shared.nodes.FishPathNode;

	public class SwimStyle
	{		
		public var node:FishPathNode;

		// update fish's movement towards current target point
		// 
		public function update(node:FishPathNode, time:Number):Boolean
		{
			this.node = node;
			if(node.path.getCurrentData().filmable){
				//trace("filmable:"+node.entity.get(Id).id)
				node.filmable.isFilmable = true;
			}else{
				node.filmable.isFilmable = false;
			}
			// overidden by subclasses- return true when target has been reached
			// good idea to process picking the next target before returning
			return	true;
		}
		
		public function advanceTo(nextIndex:int, forceIndex:Boolean = false):void{
			node.path.nextIndex = nextIndex;
			if(forceIndex){
				node.path.currentIndex = nextIndex;
			}
			//node.path.currentIndex = nextIndex;
		}
	}
}