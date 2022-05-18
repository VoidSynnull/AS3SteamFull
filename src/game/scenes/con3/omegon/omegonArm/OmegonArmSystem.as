package game.scenes.con3.omegon.omegonArm
{
	import game.systems.GameSystem;
	
	public class OmegonArmSystem extends GameSystem
	{
		public function OmegonArmSystem()
		{
			super(OmegonArmNode, updateNode);
		}
		
		private function updateNode(node:OmegonArmNode, time:Number):void
		{
			node.display.displayObject.height = node.arm.handSpatial.y - node.display.displayObject.y;
		}
	}
}