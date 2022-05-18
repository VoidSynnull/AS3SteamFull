package game.scenes.survival1.shared
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.ActionBase;
	import org.flintparticles.common.emitters.Emitter;
	import org.flintparticles.common.particles.Particle;
	import org.flintparticles.twoD.particles.Particle2D;
	
	public class Wind extends ActionBase
	{
		public function Wind(velocity:Point = null)
		{
			if(velocity == null)
				velocity = new Point();
			
			this.velocity = velocity;
		}
		
		public function setVelocity(velocity:Point):void
		{
			this.velocity = velocity;
		}
		
		public function setVelocityX(x:Number):void
		{
			velocity.x = x;
		}
		
		public function setVelocityY(y:Number):void
		{
			velocity.y = y;
		}
		
		public function getVelocity():Point
		{
			return velocity;
		}
		
		private var velocity:Point;
		
		override public function update( emitter:Emitter, particle:Particle, time:Number ):void
		{
			var p:Particle2D = Particle2D( particle );
			p.x += velocity.x * time;
			p.y += velocity.y * time;
		}
	}
}