package game.scenes.virusHunter.lungs.systems 
{
	import flash.geom.Point;
	
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.components.Emitter;
	
	import org.flintparticles.twoD.particles.Particle2D;

	public class SmokeSystem extends System
	{
		private var current:Spatial;
		private var previous:Point;
		private var emitter:Emitter;
		
		public function SmokeSystem(current:Spatial, emitter:Emitter) 
		{
			this.current = current;
			this.previous = new Point(current.x, current.y);
			this.emitter = emitter;
		}
		
		override public function update(time:Number):void
		{
			var xDifference:Number = current.x - previous.x;
			var yDifference:Number = current.y - previous.y;
			
			var particles:Array = emitter.emitter.particlesArray;
			if(particles == null) return;
			
			for(var i:uint = 0; i < particles.length; i++)
			{
				var particle:Particle2D = particles[i];
				particle.x -= xDifference;
				particle.y -= yDifference;
			}
			
			previous.x = current.x;
			previous.y = current.y;
		}
	}
}