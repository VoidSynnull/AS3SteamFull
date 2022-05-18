package game.scenes.arab1.palaceExterior.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.arab1.palaceExterior.PalaceExterior;
	import game.scenes.arab1.palaceExterior.nodes.PalaceGuardNode;
	import game.util.EntityUtils;
	
	public class PalaceGuardSystem extends ListIteratingSystem
	{
		
		public function PalaceGuardSystem($scene:PalaceExterior)
		{
			super(PalaceGuardNode, updateNode);
			_scene = $scene;
		}
		
		private function updateNode($node:PalaceGuardNode, $time:Number):void{
			if(!pause){
				if(EntityUtils.distanceBetween($node.entity, _scene.player) <= $node.palaceGuard.alertDistance && !$node.palaceGuard.blinded){
					_scene.stopPlayer();
				}
			}
		}
		
		public var pause:Boolean = false;
		
		private var _scene:PalaceExterior;
	}
}