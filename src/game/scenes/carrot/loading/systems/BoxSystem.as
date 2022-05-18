package game.scenes.carrot.loading.systems 
{
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Motion;
	import engine.managers.SoundManager;
	
	import game.data.sound.SoundModifier;
	import game.scenes.carrot.loading.components.Box;
	import game.scenes.carrot.loading.nodes.BoxNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.MotionUtils;

	public class BoxSystem extends GameSystem
	{
		
		public function BoxSystem() 
		{
			super( BoxNode, updateNode );
			super._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode( node:BoxNode, time:Number ):void
		{
			var box:Box = node.box;
			
			if ( box.currentLevel < box.level )
			{
				// if crate has passed target, reset
				if ( node.spatial.y > box.target )
				{
					var sound:String = "chute_0" + box.chute + ".mp3";
					node.audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
					
					box.currentLevel++;	// increment level
					if( box.currentLevel == box.level )
					{
						stopCrate( node );
					}
					else
					{
						startCrate( node );
					}
				}
			}
			else
			{
				// if crates have completed a cycle boxes, wait before to start cycle again
				box.time += time; 
				if ( box.time > box.waitTime )
				{
					box.time = 0;
					box.currentLevel = 0;
	
					startCrate( node );
				}
			}
		}
		
		private function stopCrate( node:BoxNode ):void
		{
			var motion:Motion = node.motion
	
			node.box.display.visible = false;
			motion.velocity.y = 0;
			motion.rotationAcceleration = 0;
			motion.rotationVelocity = 0;
			motion.acceleration.y = 0;
		}
		
		private function startCrate( node:BoxNode ):void
		{
			var motion:Motion = node.motion;
			var box:Box = node.box;
			
			node.box.display.visible = true;
			node.spatial.y = box.start;
			motion.velocity.y = box.initVelocity;
			motion.acceleration.y = MotionUtils.GRAVITY;
			node.spatial.rotation = Math.random() * 360;
			motion.rotationAcceleration = Math.random() * 20;
			motion.rotationVelocity = Math.random() * 100 - 4;
		}

	}
}