package game.scenes.survival5.chase.states
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.Emitter;
	import game.data.animation.entity.character.Run;
	import game.scenes.reality2.cheetahRun.CheetahRun;
	import game.util.DisplayUtils;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;

	public class RunningCharacterRun extends RunningCharacterState
	{
		private const EMITTER_ID:String = "dust";
		private var _correctedDustEmitter:Boolean;
		
		
		public function RunningCharacterRun()
		{
			super.type = RunningCharacterState.RUN;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			_correctedDustEmitter = false;
			node.looperCollider.isHit = false;
			node.looperCollider.collisionType = null;
			
			setAnim( Run );
			if( _uiHead && node.motionMaster.active )
			{
				SkinUtils.setEyeStates( _uiHead, "open", "forward" );
				_eyeState.value = "open_still";
				Spatial( _uiHead.get( Spatial )).rotation = 0;
			}
			if(_isReality)
				CheetahRun(node.owningGroup.group.shellApi.currentScene).numJumps = 0;
		}
		
		override public function check():Boolean
		{
			switch( node.looperCollider.collisionType )
			{
				case "pit":
					if( !node.owningGroup.group.shellApi.checkEvent( FELL_IN_PIT ))
					{
						node.owningGroup.group.shellApi.triggerEvent( FELL_IN_PIT, true );
					}
					return true;
				
				default:
					node.fsmControl.setState( RunningCharacterState.STUMBLE );
					return true;
			}
		}
		
		override public function update( time:Number ):void
		{
			super.update( time );
			if( !_correctedDustEmitter )
			{
				var emitterEntity:Entity = node.entity.group.getEntityById( EMITTER_ID );
				if( emitterEntity )
				{
					alterDustEmitter( emitterEntity );
					_correctedDustEmitter = true;
				}
			}
		}
		
		private function alterDustEmitter( emitterEntity:Entity ):void
		{
			var emitter:Emitter = emitterEntity.get( Emitter );
			var velocity:Velocity = emitter.emitter.initializers[ 3 ] as Velocity;
			var position:Position = emitter.emitter.initializers[ 4 ] as Position;
			
			velocity.zone = new LineZone( new Point( -20, 4 ), new Point( -100, -15 ));
			position.zone = new LineZone( new Point( 2, -2 ), new Point( -12, 0 ));
			
			var drift:RandomDrift = emitter.emitter.actions[ 1 ] as RandomDrift;
			var accelerate:Accelerate = emitter.emitter.actions[ 3 ] as Accelerate;
			
			
			drift.driftX = -30;
			drift.driftY = 20;
			
			accelerate.x = -65;
			accelerate.y = -15;
			
			DisplayUtils.moveToBack( Display( emitterEntity.get( Display )).displayObject );
		}
	}
}