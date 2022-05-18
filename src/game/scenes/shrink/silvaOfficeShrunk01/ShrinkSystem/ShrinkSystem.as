package game.scenes.shrink.silvaOfficeShrunk01.ShrinkSystem
{
	import game.systems.GameSystem;
	
	public class ShrinkSystem extends GameSystem
	{
		private const SHRINK:String = "shrink";
		
		public function ShrinkSystem()
		{
			super( ShrinkNode, updateNode );
		}
		
		public function updateNode( node:ShrinkNode, time:Number ):void
		{
			if( !node.shrink.isShrunk )
			{
				if( node.shrink.shrink )
				{
					shrink( node );
				}
			}
		}
		
		private function shrink( node:ShrinkNode ):void
		{
			if( !node.shrink.shrinking )
			{
				node.audio.playCurrentAction( SHRINK );

				node.shrink.shrinking = true;
				node.tween.to( node.spatial, node.shrink.shrinkTime, { scale : node.shrink.scale, onComplete : node.shrink.shrunk });
			}
		}
	}
}