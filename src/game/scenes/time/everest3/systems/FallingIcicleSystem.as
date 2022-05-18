package game.scenes.time.everest3.systems
{
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.motion.time.FixedTimestep;
	import game.scenes.time.everest3.components.FallingIcicle;
	import game.scenes.time.everest3.nodes.FallingIcicleNode;
	import game.systems.GameSystem;
	
	public class FallingIcicleSystem extends GameSystem
	{
		public function FallingIcicleSystem()
		{
			super(FallingIcicleNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function updateNode(node:FallingIcicleNode, time:Number):void
		{
			var icicle:FallingIcicle = node.fallingIcicle;
			var icicleDisplay:Display = node.display;
			var motion:Motion = node.motion;//icicle.hit.get(Motion);
			var spatial:Spatial = node.spatial;//icicle.hit.get(Spatial);
			var playerSpatial:Spatial = this.group.shellApi.player.get(Spatial);
			
			switch(icicle.state)
			{
				case "stopped":
					icicleDisplay.visible = false;
					
					if(playerSpatial.y > icicle.range.x && playerSpatial.y < icicle.range.y)
						icicle.state = "drop"
					break;
				
				case "drop":
					trace("Icicle's Name: " + node.entity.name);
					icicleDisplay.visible = true;
					spatial.x = playerSpatial.x;
					spatial.y = playerSpatial.y - 400;
					motion.velocity.y = icicle.velocity;
					
					for each(var snowball:Entity in icicle.snowballs)
					{
						var snowSpatial:Spatial = snowball.get(Spatial);
						snowSpatial.x = Math.random() * 80 - 40;
						snowSpatial.y = - Math.random() * 140;
					}
					
					icicle.state = "falling";
					// sound
					group.shellApi.triggerEvent("icicle_fall");
					
				case "falling":
					if(spatial.y > playerSpatial.y + 500)
						icicle.state = "gone";
					break;
				
				case "gone":
					waitCounter += time;
					
					if(waitCounter > icicle.waitTime)
					{
						icicle.state = "stopped";
						waitCounter = 0;
						soundPlayed = false;
					}
					break;
			}
			/*
			if(playerHit.hit != null && playerHit.hit == node.entity && !soundPlayed)
			{
				group.shellApi.triggerEvent("icicle_hit");
				soundPlayed = true;
			}
			*/
		}
		
		private var soundPlayed:Boolean = false;
		private var waitCounter:Number = 0;
	}
}