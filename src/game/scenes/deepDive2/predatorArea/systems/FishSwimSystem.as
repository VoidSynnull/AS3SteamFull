package game.scenes.deepDive2.predatorArea.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.deepDive2.predatorArea.nodes.FishSwimNode;
	
	public class FishSwimSystem extends ListIteratingSystem
	{
		public function FishSwimSystem()
		{
			super(FishSwimNode, updateNode);
		}
		
		private function updateNode($node:FishSwimNode, $time:Number):void{
			// check for rotation values and correct fish's facing during swimming (so the fish don't look like they are swimming upside-down)
			
			if($node.spatial.rotation >= 90 || $node.spatial.rotation <= -90){
				$node.spatial.scaleY = -1;
			} else {
				$node.spatial.scaleY = 1;
			}
		}
	}
}