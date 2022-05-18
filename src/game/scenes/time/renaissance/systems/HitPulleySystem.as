package game.scenes.time.renaissance.systems
{	
	import flash.geom.Point;
	
	import ash.core.Engine;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.CurrentHit;
	import game.scenes.time.renaissance.components.HitPulley;
	import game.scenes.time.renaissance.nodes.HitPulleyNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;


	public class HitPulleySystem extends GameSystem
	{
		private static const STOPPED:String = "stopped";
		// node states
		private static const RIGHT:String 	= "right";
		private static const LEFT:String 	= "left";
		private static const FLAT:String 	= "flat";
		
		private var motionState:String = STOPPED;
		private var playerHit:CurrentHit;
		
		private var movableLeft:Boolean = true;
		private var movableRight:Boolean = true;
		private var stateChanged:Boolean = false;
		
		override public function addToEngine( systemManager:Engine ):void
		{
			playerHit = group.shellApi.player.get( CurrentHit );
			super.addToEngine(systemManager);
		}
		
		public function HitPulleySystem()
		{
			super( HitPulleyNode, updateNode );
		}
		
		public function updateNode(node:HitPulleyNode, time:Number):void
		{
			updateState(node);
			
			updateMotion(node);
		}
		
		private function updateState( node:HitPulleyNode ):void
		{
			var hitPulley:HitPulley = node.hitPulley;
			var id:Id = node.id;
			
			if( !playerHit.hit || ( playerHit.hit.name != RIGHT && playerHit.hit.name != LEFT && playerHit.hit.name != FLAT ))
			{
				hitPulley.hitSource = false;
				motionState  = STOPPED;
			}
			
			else if( playerHit.hit == node.entity )
			{				
				hitPulley.hitSource = true;
				// get direction to move from pulley
				switch( id.id )
				{
					case RIGHT:
					{	
						// shift base pulley right
						if( movableRight )
						{
							motionState = RIGHT;
							if( !stateChanged )
							{
								stateChanged = true;
							}
						}
						break;
					}
					case LEFT:
					{
						// shift base pulley left
						if( movableLeft )
						{
							motionState = LEFT;
							if( !stateChanged )
							{
								stateChanged = true;
							}
						}
						break;
					}
					case FLAT:
					{
						// flat pulley doesn't do anything on its own
						motionState  = STOPPED;
						if( !stateChanged )
						{
							stateChanged = true;
						}
						break;
					}
				}
			}
		}
		
		private function updateMotion( node:HitPulleyNode ):void
		{
			var hitPulley:HitPulley = node.hitPulley;
			var motion:Motion = node.motion;
			var id:Id = node.id;
			var spatial:Spatial = node.spatial;
			var distance1:Number = GeomUtils.dist( spatial.x, spatial.y, hitPulley.pointOne.x, hitPulley.pointOne.y );
			var distance2:Number = GeomUtils.dist( spatial.x, spatial.y, hitPulley.pointTwo.x, hitPulley.pointTwo.y );
			
			switch( motionState )
			{
				case STOPPED:
					//stoped
					stopPulley( node );
					break;
				
				case RIGHT:		
					if( movableRight )
					{
						movableLeft = true;
						// move until pulley being stood on reaches its end
						if( hitPulley.hitSource && id.id == RIGHT )
						{ 	
							if( distance1 < 6 )
							{
								stopPulley( node );
								movableRight = false;
							}
						}
						else
						{
							if( stateChanged )
							{
								stateChanged = false;
								super.group.shellApi.triggerEvent( "pulley_move_sound" );
							}
							movableRight = true;
						}
						motion.velocity = moveTo( node, hitPulley.pointOne );
					}
					else
					{
						stopPulley( node );
					}
				break;
				
				case LEFT:
					if( movableLeft )
					{
						movableRight = true;
						// move until pulley being stood on reaches its end
						if( hitPulley.hitSource && id.id == LEFT )
						{
							if( distance2 < 6 )
							{
								stopPulley( node );
								movableLeft = false;
							}
						}
						else
						{
							if( stateChanged )
							{
								stateChanged = false;
								super.group.shellApi.triggerEvent( "pulley_move_sound" );
							}
							movableLeft = true;
						}
						
						motion.velocity = moveTo( node, hitPulley.pointTwo ); 
					}
					else
					{
						stopPulley( node );
					}
					break;
			}
		}
		
		private function stopPulley( node:HitPulleyNode ):void
		{
			var motion:Motion = node.motion;
			motionState = STOPPED;
			
			if( Math.abs( motion.velocity.x ) > 0 || Math.abs( motion.velocity.y ) > 0 )
			{
				motion.acceleration.x = motion.velocity.x = motion.previousAcceleration.x = motion.totalVelocity.x = 0;
				motion.acceleration.y = motion.velocity.y = motion.previousAcceleration.y = motion.totalVelocity.y = 0;
			}
		}

		private function moveTo( node:HitPulleyNode, target:Point ):Point
		{
			var hitPulley:HitPulley = node.hitPulley;
			var spatial:Spatial = node.spatial;
			var dir:Number;
			var velocity:Point; 
			
			dir = GeomUtils.degreesBetween( target.x, target.y, spatial.x, spatial.y );
			
			velocity = new Point();
			velocity.x = Math.cos( GeomUtils.degreeToRadian( dir )) * hitPulley.acceleration;
			velocity.y = Math.sin( GeomUtils.degreeToRadian( dir )) * hitPulley.acceleration;			
			return velocity;
		}
	}
}