package game.scenes.backlot.extSoundStage2
{
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class SwingSystem extends GameSystem
	{
		private var player:Entity;
		
		public function SwingSystem(player:Entity)
		{
			super(SwingNode, updateNode);
			
			this.player = player;
			this._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:SwingNode, time:Number):void
		{
			var display:Display = this.player.get(Display);
			
			if(node.display.displayObject.hitTestObject(display.displayObject))
			{
				if(!node.swing.isColliding)
				{
					node.swing.isColliding = true;
					
					var motion:Motion = player.get(Motion);
					
					node.motion.rotationVelocity = -motion.velocity.x * 0.15;
				}
			}
			else node.swing.isColliding = false;
			
			var delta:Number = -node.spatial.rotation;
			
			if(Math.abs(delta) > 50)
			{
				if(delta > 50) delta = 50;
				else if(delta < -50) delta = -50;
			}
			
			if(Math.abs(delta) < 5) node.motion.rotationFriction = 20;
			else node.motion.rotationFriction = 60;
			
			if(delta > 0) node.motion.rotationAcceleration = delta * 10 + 10;
			else node.motion.rotationAcceleration = delta * 10 - 10;
		}
	}
}