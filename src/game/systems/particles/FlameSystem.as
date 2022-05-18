package game.systems.particles
{
	import flash.display.Sprite;
	
	import game.components.particles.Flame;
	import game.data.particles.FlameData;
	import game.nodes.particles.FlameNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.BitmapUtils;
	import game.util.Utils;
	
	public class FlameSystem extends GameSystem
	{
		public function FlameSystem()
		{
			super(FlameNode, updateNode);
			super._defaultPriority = SystemPriorities.lowest;
		}
		
		public function updateNode(node:FlameNode, time:Number):void
		{
			node.flame.time += time;
			if(node.flame.time >= node.flame.wait)
			{
				node.flame.time = 0;
				node.flame.wait = Utils.randNumInRange(0.05, 0.1);
				
				this.addFlame(node);
			}
			
			this.updateFlames(node, time);
		}
		
		private function addFlame(node:FlameNode):void
		{
			var flame:Flame = node.flame;
			
			var data:FlameData;
			if(flame.pool.length > 0)
			{
				data = flame.pool.pop();
				data.reset();
			}
			else
			{
				var sprite:Sprite 		= BitmapUtils.createBitmapSprite(flame.clip, 1, null, true, 0, flame.data);
				sprite.mouseChildren 	= false;
				sprite.mouseEnabled 	= false;
				data = new FlameData(sprite);
			}
			
			data.sprite.rotation 		= Math.random() * 180 - 90;
			data.sprite.x 				= Math.random() * 40 - 20;
			data.sprite.y				= 0;
			data.sprite.scaleX 			= data.sprite.scaleY = 0.1;
			data.sprite.alpha 			= 0.7;
			
			if(flame.isFront) flame.container.addChild(data.sprite);
			else flame.container.addChildAt(data.sprite, 0);
			
			flame.flames.push(data);
		}
		
		private function updateFlames(node:FlameNode, time:Number):void
		{
			var flame:Flame = node.flame;
			
			for(var i:int = flame.flames.length - 1; i >= 0; --i)
			{
				var data:FlameData 		= node.flame.flames[i];
				data.velocityY 			-= 9 * time;
				data.sprite.y 			+= data.velocityY;
				data.sprite.rotation 	-= data.sprite.rotation / 0.4 * time;
				data.sprite.x 			-= data.sprite.x / 1.25 * time;
				
				if(data.isShrinking)
				{
					data.sprite.scaleX = data.sprite.scaleY += data.velocityY * time;
					if(data.sprite.scaleX < 0.1)
					{
						
						flame.container.removeChild(data.sprite);
						flame.flames.splice(i, 1);
						flame.pool.push(data);
					}
				}
				else
				{
					data.sprite.scaleX = data.sprite.scaleY += 4 * time;
					if(data.sprite.scaleX > data.targetScale)
					{
						data.isShrinking = true;
					}
				}
			}
		}
	}
}