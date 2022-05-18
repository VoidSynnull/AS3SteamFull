package game.systems 
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.group.Scene;
	import engine.systems.CameraSystem;
	
	import game.nodes.ParticleMovementNode;
	
	import org.flintparticles.twoD.particles.Particle2D;

	public class ParticleMovementSystem extends System
	{
		private var emitters:NodeList;
		private var camera:CameraSystem;
		private var previous:Point;
		
		public function ParticleMovementSystem(scene:Scene) 
		{
			this.camera = scene.shellApi.camera;
			this.previous = new Point(-camera.x, -camera.y);
		}
		
		override public function update(time:Number):void
		{
			/**
			 * For some reason, the camera's x and y are negative even though the scene takes place mostly
			 * in +(x, y) space. So to change that I negated it to make it positive.
			 */
			
			//If no positional change has occurred, don't bother doing anything.
			if(-camera.x == previous.y && -camera.y == previous.y) return;
			
			//Get the change in current and previous camera positions.
			var xDifference:Number = -camera.x - previous.x;
			var yDifference:Number = -camera.y - previous.y;
			
			var particles:Array;
			var particle:Particle2D;
			
			//For each node...
			for(var movement:ParticleMovementNode = this.emitters.head; movement; movement = movement.next)
			{
				//...get its particles.
				particles = movement.emitter.emitter.particlesArray;
				
				//For each particle...
				for(var i:uint = 0; i < particles.length; i++)
				{
					particle = particles[i];
					
					//...apply the difference.
					particle.x -= xDifference;
					particle.y -= yDifference;
					
				}
			}
			
			//Reset the previous camera position to the current.
			this.previous.x = -this.camera.x;
			this.previous.y = -this.camera.y;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this.emitters = systemManager.getNodeList(ParticleMovementNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(ParticleMovementNode);
			this.emitters = null;
		}
	}
}