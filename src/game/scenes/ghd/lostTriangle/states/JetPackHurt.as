package game.scenes.ghd.lostTriangle.states
{
	import game.data.animation.entity.character.Hurt;
	import game.scenes.ghd.neonWiener.NeonWiener;
	
	import org.flintparticles.common.initializers.ColorInit;

	public class JetPackHurt extends JetPackState
	{
		public function JetPackHurt()
		{
			super.type = JetPackState.HURT;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{			
			setAnim( Hurt );
			node.charMotionControl.ignoreVelocityDirection = true;
			node.charMotionControl.spinning = true;
			node.charMotionControl.spinCount = 2;							
			node.charMotionControl.spinSpeed = node.charMotionControl.duckRotation;
			super.updateStage = this.updateSpin;
			
			var colorInit:ColorInit = _emitter.emitter.initializers[ 3 ] as ColorInit;
			node.jetpackHealth.currentHealthValue++;
			var damageLevel:int = Math.ceil( node.jetpackHealth.currentHealthValue/2 );
			if( damageLevel < node.jetpackHealth.COLORS.length ) 
			{
				colorInit.maxColor = node.jetpackHealth.COLORS[ damageLevel ];
				colorInit.minColor = node.jetpackHealth.COLORS[ damageLevel - 1 ];
			}
			else
			{
				node.owningGroup.group.shellApi.triggerEvent( "failed_lost_triangle" );
			}
		}
		
		override public function check():Boolean
		{
			return false;
		}
		
		override public function update( time:Number ):void
		{
			super.update( time );
			super.updateStage();
		}
		
		private function updateSpin():void
		{
			if ( node.charMotionControl.spinStopped )
			{	
				returnToHover();
			}
		}
		
		private function returnToHover():void
		{
			node.charMotionControl.animEnded = false;
			node.motion.rotationVelocity = 0;
			node.motion.rotation = 0;
			node.motion.acceleration.y = 400;
			
			if( _input.inputActive )
			{
				node.fsmControl.setState( JetPackState.PROPEL ); 
			}
			else
			{
				node.fsmControl.setState( JetPackState.HOVER );
			}
		}
	}
}