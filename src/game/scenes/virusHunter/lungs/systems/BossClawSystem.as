package game.scenes.virusHunter.lungs.systems 
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.lungs.Lungs;
	import game.scenes.virusHunter.lungs.components.Alveoli;
	import game.scenes.virusHunter.lungs.components.BossClaw;
	import game.scenes.virusHunter.lungs.components.BossState;
	import game.scenes.virusHunter.lungs.nodes.BossClawNode;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.util.Utils;

	public class BossClawSystem extends ListIteratingSystem
	{
		private var elapsedTime:Number = 0;
		private var waitTime:Number = Utils.randNumInRange(5, 10);
		private var resetPoint:Point = new Point(-3, -267);
		private var scene:Lungs;
		
		public function BossClawSystem(scene:Lungs) 
		{
			super(BossClawNode, updateNode);
			
			this.scene = scene;
		}
		
		private function updateNode(node:BossClawNode, time:Number):void
		{
			var claw:BossClaw = node.claw;
			
			switch(node.state.state)
			{
				case BossState.INTRO_STATE:
					move(claw.target, node, 300);
					
					if(isAtTarget(claw.target, node.spatial, 20))
						claw.target = new Point(Utils.randInRange(-50, 50), Utils.randInRange(-350, -450));
				break;
				
				case BossState.ATTACK_MOVE_STATE:
				case BossState.ATTACK_STATE:
					if(!node.claw.isActive)
					{
						node.spatial.x = -3;
						node.spatial.y = -267;
						node.spatial.rotation = 0;
						return;
					}
					
					if(claw.degree > 0)
					{
						node.spatial.rotation += 50 * time;
						if(node.spatial.rotation > claw.degree) claw.degree *= -1;
					}
					else
					{
						node.spatial.rotation -= 50 * time;
						if(node.spatial.rotation < claw.degree) claw.degree *= -1;
					}
					
					move(claw.target, node, 200);
					
					if(isAtTarget(claw.target, node.spatial, 20))
					{
						claw.target = new Point(Utils.randInRange(-50, 50), Utils.randInRange(-350, -550));
						Alveoli(node.state.alveoli.get(Alveoli)).isHit = true;
						
						var health:MovieClip = Display(this.scene.joeHealth.get(Display)).displayObject["content"]["bar"] as MovieClip;
						health.width -= 0.5;
						
						if(health.width <= 1)
						{
							var target:DamageTarget = this.group.shellApi.player.get(DamageTarget);
							target.damage = target.maxDamage;
						}
					}
				break;
				
				default:
					if(!node.claw.isActive)
					{
						node.spatial.x = -3;
						node.spatial.y = -267;
						node.spatial.rotation = 0;
						return;
					}
					
					move(this.resetPoint, node, 100);
					
					if(isAtTarget(this.resetPoint, node.spatial, 10))
					{
						node.spatial.x = -3;
						node.spatial.y = -267;
						node.spatial.rotation = 0;
						node.claw.isActive = false;
					}
				break;
			}
		}
		
		private function move(target:Point, node:BossClawNode, speed:Number):void
		{
			var angle:Number = Math.atan2(target.y - node.spatial.y, target.x - node.spatial.x);
			node.motion.velocity.x = Math.cos(angle) * speed;
			node.motion.velocity.y = Math.sin(angle) * speed;
		}
		
		private function isAtTarget(target:Point, spatial:Spatial, distance:Number):Boolean
		{
			if(Math.abs(target.x - spatial.x) > distance) return false;
			if(Math.abs(target.y - spatial.y) > distance) return false;
			return true;
		}
	}
}