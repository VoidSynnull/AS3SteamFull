package game.scenes.virusHunter.lungs.systems 
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.lungs.components.BossState;
	import game.scenes.virusHunter.lungs.nodes.BossArmNode;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.util.GeomUtils;
	import game.util.Utils;

	public class BossArmSystem extends ListIteratingSystem
	{
		private var elapsedTime:Number = 0;
		private var waitTime:Number = Utils.randNumInRange(5, 10);
		private var resetPoint:Point = new Point(0, 150);
		
		public function BossArmSystem() 
		{
			super(BossArmNode, updateNode);
		}
		
		private function updateNode(node:BossArmNode, time:Number):void
		{
			switch(node.state.state)
			{
				case BossState.ATTACK_MOVE_STATE:
				case BossState.ATTACK_STATE:
					if(!node.arm.isActive) return;
					
					var degrees:Number = GeomUtils.degreesBetween(node.spatial.x, node.spatial.y, node.followTarget.target.x, node.followTarget.target.y);
					node.spatial.rotation = degrees - 90;
					
					if(node.damageTarget.isHit)
					{
						node.damageTarget.isHit = false;
						var boss:Entity = this.group.getEntityById("boss");
						var audio:Audio = boss.get(Audio);
						
						if(node.damageTarget.damage < node.damageTarget.maxDamage)
						{
							var array:Array = [1, 4, 6];
							audio.play(SoundManager.EFFECTS_PATH + "flesh_impact_0" + array[Utils.randInRange(0, array.length-1)] + ".mp3");
							
							var damage:Entity = this.group.getEntityById("arm" + (node.state.currentIndex+1) + "damage");
							var display:Display = damage.get(Display);
							if(!display.visible)
							{
								display.visible = true;
								var timeline:Timeline = damage.get(Timeline);
								timeline.gotoAndPlay("start");
								timeline.handleLabel("end", Command.create(handleEnd, timeline, display));
							}
						}
						else if(!node.damageTarget.isTriggered)
						{
							node.damageTarget.isTriggered = true;
							
							this.group.removeEntity(this.group.getEntityById("claw" + (node.state.currentIndex + 1)));
							
							var enemySpawn:EnemySpawn = boss.get(EnemySpawn);
							enemySpawn.rate = 1;
							enemySpawn.max++;
							enemySpawn.ignoreOffScreenSleep = true;
							
							audio.play(SoundManager.EFFECTS_PATH + "flesh_impact_05.mp3");
							
							node.state.remainingSides.remove(node.state.currentIndex);
							node.state.state = BossState.HURT_STATE;
							
							for(var x:uint = 1; x <= 6; x++)
							{
								var entity:Entity = this.group.getEntityById("segment" + (node.state.currentIndex+1) + x);
								if(entity) this.group.removeEntity(entity);
							}
						}
					}
				break;
			}
		}
		
		private function handleEnd(timeline:Timeline, display:Display):void
		{
			timeline.stop();
			display.visible = false;
		}
	}
}