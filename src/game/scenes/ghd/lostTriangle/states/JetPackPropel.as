package game.scenes.ghd.lostTriangle.states
{
	import game.data.animation.entity.character.Soar;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.counters.ZeroCounter;

	public class JetPackPropel extends JetPackState
	{
		public function JetPackPropel()
		{
			super.type = JetPackState.PROPEL;
		}
		
		override public function start():void
		{
			setAnim( Soar );
			node.audio.playCurrentAction( JetPackState.TRIGGER );
			_emitter.emitter.counter = new Steady( 20 );
			_emitter.emitter.start();
			node.jetpackHealth.hurting = false;
			
			if( !node.jetpackHealth.launched )
			{
				node.jetpackHealth.launched = true;
				
				node.charMotionControl.gravity *= .4;
				node.motion.maxVelocity.y = 300;
				node.motion.acceleration.y = 400;
			}
		}
		
		override public function update( time:Number ):void 
		{
			node.motion.velocity.y -= 1000 * time;
		}
		
		override public function exit():void
		{
			node.motion.acceleration.y = 400;
			node.audio.stopActionAudio( TRIGGER );
			
			_emitter.emitter.counter = new ZeroCounter();
		}
	}
}