package game.scenes.time.china.systems
{
	import ash.core.Engine;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.time.china.components.FallingBrick;
	import game.scenes.time.china.nodes.FallingBrickNode;
	import game.systems.GameSystem;
	
	public class FallingBrickSystem extends GameSystem
	{
		public function FallingBrickSystem()
		{
			super( FallingBrickNode, updateNode );
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			playerSpatial = this.group.shellApi.player.get(Spatial);
			super.addToEngine(systemManager);
		}
		
		public function updateNode( node:FallingBrickNode, time:Number ):void
		{
			var brick:FallingBrick = node.fallingBrick;
			var brickDisplay:Display = node.display;
			var brickMotion:Motion = brick.hitMotion;
			var brickSpatial:Spatial = brick.hitSpatial;
			
			switch(brick.state)
			{
				case "stopped":
					brickDisplay.visible = false;
					
					if(playerSpatial.x > brick.range.x && playerSpatial.x < brick.range.width
						&& playerSpatial.y > brick.range.y && playerSpatial.y < brick.range.height)
					{
						brick.state = "drop"
					}
					break;
				
				case "drop":
					group.shellApi.triggerEvent("brick_falls");
					brickDisplay.visible = true;
					brickSpatial.x = brick.startPos.x;
					brickSpatial.y = brick.startPos.y;
					brickMotion.velocity.y = brick.velocity;
					brickMotion.rotationVelocity = Math.random() * (brick.spinSpeed.y - brick.spinSpeed.x) + brick.spinSpeed.x;
					brick.state = "falling";
					
				case "falling":
					if(brickSpatial.y > brick.scene.sceneData.bounds.bottom)
						brick.state = "fell";
					break;
				
				case "fell":
					waitCounter += time;
					
					if(waitCounter > brick.waitTime)
					{
						brick.state = "stopped";
						waitCounter = 0;
					}
					break;
			}
		}
		
		private var playerSpatial:Spatial;
		private var waitCounter:Number = 0;
	}
}