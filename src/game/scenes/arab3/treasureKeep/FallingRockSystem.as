package game.scenes.arab3.treasureKeep
{
	import engine.components.Spatial;
	
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	
	public class FallingRockSystem extends GameSystem
	{
		public function FallingRockSystem()
		{
			super(FallingRockNode, updateNode, addedNode);
		}
		
		public function addedNode(node:FallingRockNode):void
		{
			node.motion.maxVelocity.y = 800;
		}
		
		public function updateNode(node:FallingRockNode, time:Number):void
		{
			var rock:FallingRock = node.rock;
			var playerSpatial:Spatial = this.group.shellApi.player.get(Spatial);
			
			switch(rock.state)
			{
				case rock.FALLING: 
					updateFall(node, time);
					break;
				case rock.LOCKED: 
					updateLocked(node, time);
					break;
				case rock.RESETING:
					updateReset(node, time);
					break;
			}
		}
		
		private function updateLocked(node:FallingRockNode, time:Number):void
		{
			var rock:FallingRock = node.rock;
			if(rock.stateChanged){
				rock.timer = 0;
				node.spatial.y = rock.startY;
				node.motion.zeroAcceleration();
				node.motion.zeroMotion();
				rock.stateChanged = false;
				node.display.visible = false;
			}
		}
		
		private function updateReset(node:FallingRockNode, time:Number):void
		{
			var rock:FallingRock = node.rock;
			if(rock.stateChanged){
				rock.timer = 0;
				rock.stateChanged = false;
				node.display.visible = false;
			}
			if(rock.timer < rock.resettime + rock.resetOffet){
				rock.timer += time;
			}
			else{
				resetRock(node);
			}
		}
		
		private function resetRock(node:FallingRockNode):void
		{
			var rock:FallingRock = node.rock;
			var spawnX:Number = GeomUtils.randomInRange(rock.xMin,rock.xMax);
			
			node.spatial.x = spawnX;
			node.spatial.y = rock.startY - GeomUtils.randomInRange(0,30);
			
			node.motion.zeroAcceleration();
			node.motion.zeroMotion();
			
			rock.setState(rock.FALLING);
		}
		
		private function updateFall(node:FallingRockNode, time:Number):void
		{
			var rock:FallingRock = node.rock;
			if(rock.stateChanged){
				node.motion.acceleration.y = rock.speed;
				node.motion.velocity.y = rock.speed;
				node.motion.rotationVelocity = rock.spinSpeed + GeomUtils.randomInt(-(rock.spinSpeed*2), rock.spinSpeed);
				rock.stateChanged = false;
				node.display.visible = true;
				node.spatial.scale = rock.scale;
			}
			
			if(node.spatial.y >= rock.yLimit){
				node.motion.zeroAcceleration();
				node.motion.zeroMotion();
				rock.setState(rock.RESETING);
			}
			
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
}