package game.scenes.shrink.silvaOfficeShrunk01.SilvaSystem
{
	import flash.geom.Point;
	
	import engine.managers.SoundManager;
	
	import game.systems.GameSystem;
	import game.util.AudioUtils;
	
	public class SilvaSystem extends GameSystem
	{
		private const LASER_SOUND:String = "shooting_laser_01_loop.mp3";
		
		public function SilvaSystem()
		{
			super( SilvaNode, updateNode );
		}
		
		public function updateNode(node:SilvaNode, time:Number):void
		{
			node.silva.time += time;
			
			var pos:Point = new Point(node.spatial.x, node.spatial.y);
			var target:Point = new Point(node.follow.target.x , node.follow.target.y);
			node.spatial.rotation = Math.atan2(target.y - pos.y, target.x - pos.x) * 180 / Math.PI;
			
			if(node.silva.state == Silva.WAIT)
			{
				if(node.silva.time > node.silva.waitTime)
				{
					node.silva.setState(Silva.AIM);
					node.follow.offset = node.silva.targetPoint;
					node.silva.charge.emitter.counter.resume();
					node.silva.charge.start = true;
					AudioUtils.play(group, SoundManager.EFFECTS_PATH + LASER_SOUND);
				}
			}
			
			if(node.silva.state == Silva.AIM)
			{
				if(node.silva.time > node.silva.aimTime - .5 && node.silva.charge.emitter.counter.running == true)
					node.silva.charge.emitter.counter.stop();
				
				node.silva.glow.alpha = node.silva.time / node.silva.aimTime;
				
				if(node.silva.time > node.silva.aimTime)
				{
					node.silva.setState(Silva.FIRE);
					node.silva.shoot.dispatch(target);
				}
			}
			
			if(node.silva.state == Silva.FIRE)
			{
				node.silva.laserSpatial.rotation = -node.spatial.rotation;
				shootLaser(node.silva, pos , target);
				node.silva.glow.alpha = (node.silva.shootTime - node.silva.time) / node.silva.shootTime
				
				if(node.silva.time > node.silva.shootTime)
				{
					node.silva.laser.graphics.clear();
					node.silva.setState(Silva.WAIT);
					node.follow.offset = node.silva.waitPoint;
				}
			}
		}
		
		private function shootLaser(silva:Silva, pos:Point, target:Point):void
		{
			var thickness:Number = silva.time * silva.laserThickness / silva.shootTime;
			target.x -= pos.x;
			target.y -= pos.y;
			silva.laser.graphics.clear();
			silva.laser.graphics.lineStyle(thickness, silva.laserColor);
			silva.laser.graphics.lineTo(target.x, target.y);
			if(silva.backFire)
			{
				target = new Point(silva.silva.x - pos.x, silva.silva.y - pos.y);
				silva.laser.graphics.lineTo(target.x, target.y);
			}
		}
	}
}