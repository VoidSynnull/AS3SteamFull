package game.scenes.virusHunter.day2Heart.systems 
{
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.day2Heart.nodes.WormTentacleNode;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.util.GeomUtils;
	import game.util.Utils;

	public class WormTentacleSystem extends ListIteratingSystem
	{
		private var creator:EnemyCreator;
		
		public function WormTentacleSystem(creator:EnemyCreator)
		{
			super(WormTentacleNode, updateNode);
			
			this.creator = creator;
		}
		
		private function updateNode(node:WormTentacleNode, time:Number):void
		{
			if(node.sleep.sleeping) return;
			
			if(node.target.isHit)
			{
				node.target.isHit = false;
				node.audio.play(SoundManager.EFFECTS_PATH + "tendrils_hit_0" + Utils.randInRange(1, 4) + ".mp3", false, SoundModifier.EFFECTS);
				
				if(node.target.damage >= node.target.maxDamage && !node.target.isTriggered)
				{
					node.target.isTriggered = true;
					node.tentacle.boss.numTentacles--;
					
					var radians:Number = GeomUtils.degreeToRadian(node.spatial.rotation);
					var x:Number = Math.cos(radians) * 300 + node.spatial.x;
					var y:Number = Math.sin(radians) * 300 + node.spatial.y;
					
					creator.createRandomPickup(x, y, false);
					creator.createRandomPickup(x, y, false);
					
					var tween:Tween = new Tween();
					node.entity.add(tween);
					var object:Object = { alpha:0, onComplete:this.group.removeEntity, onCompleteParams:[node.entity] };
					tween.to(node.entity.get(Display), 1, object);
				}
			}
		}
	}
}