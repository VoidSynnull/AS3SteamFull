package game.scenes.virusHunter.shared.systems
{	
	import ash.core.Engine;
	import ash.core.NodeList;
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.Bacteria;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.BacteriaMotionNode;
	import game.scenes.virusHunter.shared.nodes.KillCountNode;
	import game.systems.GameSystem;
	
	public class BacteriaSystem extends GameSystem
	{
		public function BacteriaSystem( creator:EnemyCreator )
		{
			super( BacteriaMotionNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode( node:BacteriaMotionNode, time:Number ):void
		{	
			if( node.bacteria.state != node.bacteria.EXPLODE )
			{
				if( node.bacteria.state == node.bacteria.FLOAT )
				{
					node.display.visible = true;
				}
				
				else if(node.bacteria.state == node.bacteria.DIE)
				{
					node.bacteria.state = node.bacteria.INACTIVE;
					node.entity.remove(Bacteria);
					_creator.releaseEntity(node.entity);
					return;
				}	
				
				if(node.damageTarget.damage > node.damageTarget.maxDamage)
				{
					var killCountNode:KillCountNode = _killCountNodes.head;
					
					killCountNode.killCount.count[ "bacteria" ]++;
					
					node.bacteria.state = node.bacteria.EXPLODE;
					node.entity.remove( MovieClipHit );
					node.timeline.gotoAndPlay( "explode" );
					return;
				}
			}
			else
			{
				if( node.timeline.currentFrameData.label == "endExplode" )
				{
					node.timeline.stop();
					node.display.visible = false;
					node.bacteria.state = node.bacteria.DIE;
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_killCountNodes = systemManager.getNodeList(KillCountNode);
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(BacteriaMotionNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
		private var _killCountNodes:NodeList;
	}
}
