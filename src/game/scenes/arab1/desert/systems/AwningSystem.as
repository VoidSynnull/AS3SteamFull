package game.scenes.arab1.desert.systems
{
	import ash.tools.ListIteratingSystem;
	
	import engine.group.Group;
	
	import game.scenes.arab1.desert.nodes.AwningNode;
	import game.scenes.arab1.desert.particles.SandFall;
	
	public class AwningSystem extends ListIteratingSystem
	{
		
		public function AwningSystem($group:Group, $sandFall:SandFall)
		{
			_group = $group;
			_sandFall = $sandFall;
			super(AwningNode, updateNode);
		}
		
		private function updateNode($node:AwningNode, $time:Number):void{
			if($node.entityIdList.entities.length > 0 && !_onAwning){
				_onAwning = true;
				if(!_sandFall.flowing){
					_sandFall.stream();
				}
			} else if($node.entityIdList.entities.length == 0) {
				_onAwning = false;
			}
		}
		
		private var _onAwning:Boolean = false;
		private var _sandFall:SandFall;
		private var _group:Group;
	}
}