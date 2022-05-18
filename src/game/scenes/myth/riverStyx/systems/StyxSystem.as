package game.scenes.myth.riverStyx.systems
{
	import ash.core.Engine;
	
	import engine.components.Audio;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.myth.riverStyx.components.StyxComponent;
	import game.scenes.myth.riverStyx.nodes.StyxNode;
	import game.systems.GameSystem;
	import game.util.MotionUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.osflash.signals.Signal;
	
	public class StyxSystem extends GameSystem
	{
		public function StyxSystem( boatMotion:Motion )
		{
			super( StyxNode, updateNode, nodeAdded );
			BOAT_MOTION = boatMotion;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			finished = new Signal();
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			HALF_WIDTH = group.shellApi.viewportWidth / 2;
			LOOP = 0;
			super.addToEngine( systemManager );
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function nodeAdded( node:StyxNode ):void
		{
			var sleep:Sleep = node.sleep;
			sleep.ignoreOffscreenSleep = true;
		}
		
		private function updateNode( node:StyxNode, time:Number ):void
		{
			switch( node.id.id )
			{
				case "stalacHit":
					stalacUpdate( node, time );
					break;
				
				case "soulHit":
					soulUpdate( node, time );
					break;
				
				case "crocHit":
					crocUpdate( node, time );
					break;
			}
		}
		
		private function stalacUpdate( node:StyxNode, time:Number ):void
		{
			var audio:Audio = node.audio;
			var motion:Motion = node.motion;
			var sleep:Sleep = node.sleep;
			var spatial:Spatial = node.spatial;
			var styx:StyxComponent = node.styx;
			var xPos:Number;
			var nextNode:StyxNode;
			
			switch( styx.state )
			{
				case SPAWN:
					xPos = Math.floor( BOAT_MOTION.x / 2240 ) * 2240 + 1259;
					
					if( BOAT_MOTION.x > xPos )
					{
						xPos += 2240;
					}
					spatial.x =  xPos;
					spatial.y = styx.origin.y;
					
					styx.state = TRIGGER;
					break;
				
				case TRIGGER:
					if( spatial.x > BOAT_MOTION.x )
					{
						if( styx.visual.alpha == 0 )
						{
							styx.visual.alpha = 1;
						}
						else if( BOAT_MOTION.x + SHAKE_STALAC_POINT > motion.x )
						{
							styx.state = BEGIN_ATTACK;
						}
					}
					break;
				
				case BEGIN_ATTACK:
					if( BOAT_MOTION.x + DROP_STALAC_POINT > motion.x )
					{
						motion.acceleration.y = MotionUtils.GRAVITY * 1/2;
					
						audio.playCurrentAction( RANDOM );
						
						styx.state = EDIT_ATTACK;
					}
					else
					{				
						motion.x += Math.random() * 4 - 2;
						motion.y += Math.random() * 4 - 2;
						motion.rotation = Math.random() * 10 - 5;
					}
					break;
				
				case EDIT_ATTACK:
					if( motion.y > SPLASH_STALAC_POINT )
					{
						styx.state = KILL_TRIGGER;
						createSplash( node );
					}
					break;
					
				case KILL_TRIGGER:	
					if( motion.y > KILL_STALAC_POINT )
					{
						motion.acceleration.y = 0;
						motion.previousAcceleration.y = 0;
						motion.velocity.y = 0;
						
						nextNode = node.next as StyxNode;
						nextNode.sleep.sleeping = false;
						nextNode.styx.state = SPAWN;
						styx.visual.alpha = 0;
						sleep.sleeping = true;
					}
					break;
			}
		}
		
		
		private function soulUpdate( node:StyxNode, time:Number ):void
		{
			var angle:Number;
			var dx:Number;
			var dy:Number;
			var audio:Audio = node.audio;	
			var motion:Motion = node.motion;
			var sleep:Sleep = node.sleep;
			var spatial:Spatial = node.spatial;
			var styx:StyxComponent = node.styx;
			
			var nextNode:StyxNode;
			
			switch( styx.state )
			{
				case SPAWN:
					spatial.x = styx.origin.x + BOAT_MOTION.x;
					spatial.y = styx.origin.y;
					
					audio.playCurrentAction( RANDOM );
		
					motion.velocity.x = 2 * SOUL_VELOCITY;
					motion.velocity.y = 0;
					styx.state = TRIGGER;
					break;
				
				case TRIGGER:
					if( spatial.x > BOAT_MOTION.x )
					{
						if( styx.visual.alpha == 0 )
						{
							styx.visual.alpha = 1;
						}
						styx.state = EDIT_ATTACK;
					}
					break

				case EDIT_ATTACK:					
					dx;// = BOAT_MOTION.x - 260 - motion.x;
					dy;// = BOAT_MOTION.y - motion.y;
					angle;// = Math.atan2( dy, dx );
							
					//motion.velocity.y -= 2.3 * Math.cos( angle );
					
					if( motion.y < styx.origin.y || motion.x < BOAT_MOTION.x - HALF_WIDTH )
					{
						motion.velocity.y = 0;
						styx.state = KILL_TRIGGER;
					}
					
					if( motion.x > BOAT_MOTION.x + 100 )
					{
						dx = BOAT_MOTION.x - motion.x;
						dy = BOAT_MOTION.y - motion.y;
						angle = Math.atan2( dy, dx );
						
						motion.velocity.y -= 2.3 * Math.cos( angle );
						//trace( "motionDown" + motion.velocity.y );
					}
					else if( motion.x < BOAT_MOTION.x  + 100 && motion.x > BOAT_MOTION.x - 250 )
					{
						dx = BOAT_MOTION.x - motion.x + 100;
						dy = BOAT_MOTION.y - motion.y;
						angle = Math.atan2( dy, dx );
						
						motion.velocity.y -= 15 * Math.cos( angle );
						//trace("motionUp" + motion.velocity.y );
					}
					
					else if( motion.x < BOAT_MOTION.x - 250 )
					{
						motion.acceleration.y = 0;
						motion.previousAcceleration.y = 0;
						motion.velocity.y = 0;
						
						nextNode = node.next as StyxNode;
					
						if( nextNode.id.id != "crocHit" )
						{
							nextNode = nextNode.next;
						}
						
						nextNode.sleep.sleeping = false;
						nextNode.styx.state = SPAWN;

						styx.visual.alpha = 0;
						sleep.sleeping = true;
					}					
					break;
				
				case KILL_TRIGGER:
					if( motion.x < BOAT_MOTION.x - HALF_WIDTH )
					{
						motion.acceleration.y = 0;
						motion.previousAcceleration.y = 0;
						motion.velocity.y = 0;
						
						nextNode = node.next as StyxNode;
						if( nextNode.id.id != "crocHit" )
						{
							nextNode = nextNode.next;
						}
						
						nextNode.sleep.sleeping = false;
						nextNode.styx.state = SPAWN;
						styx.visual.alpha = 0;
						sleep.sleeping = true;
					}
					break;
			}
		}
		
		private function crocUpdate( node:StyxNode, time:Number ):void
		{
			var audio:Audio = node.audio;
			var motion:Motion = node.motion;
			var sleep:Sleep = node.sleep;
			var spatial:Spatial = node.spatial;
			var styx:StyxComponent = node.styx;
			
			var prevNode:StyxNode;
			var nextNode:StyxNode;
			
			
			switch( styx.state )
			{
				case SPAWN:
					spatial.x = styx.origin.x + BOAT_MOTION.x;
					spatial.y = styx.origin.y;
					
					motion.velocity.x = CROC_PAN_SPEED;
					
					spatial.rotation = 0;
					styx.crocJaw.rotation = 0;
					
					styx.state = TRIGGER;
					break;
				
				case TRIGGER:
					if( spatial.x > BOAT_MOTION.x )
					{
						if( styx.visual.alpha == 0 )
						{
							styx.visual.alpha = 1;
						}
					
						styx.state = BEGIN_ATTACK;
					}
					break;
				
				case BEGIN_ATTACK:
					if( motion.x < CROC_ATTACK + BOAT_MOTION.x )
					{
						motion.velocity.y = CROC_ATTACK_VELOCITY;
						styx.state = EDIT_ATTACK;
						
						audio.playCurrentAction( RANDOM );
					}
					break;
				
				case EDIT_ATTACK:
					if( styx.crocJaw.rotation < 44 )
					{
						styx.crocBody.rotation += 4;
						styx.crocJaw.rotation += 4;
						styx.crocJaw.y -= 2;
						styx.crocJaw.x += 1;
					}
					else
					{					
						styx.state = END_ATTACK;
						
						createSplash( node );
						motion.velocity.y = 50;
					}
					break;
				
				case END_ATTACK:
					if( styx.crocJaw.rotation > 0 )
					{
						styx.crocBody.rotation -= 4;
						styx.crocJaw.rotation -= 4;
						styx.crocJaw.y += 2;
						styx.crocJaw.x -= 1;
					}
					else
					{
						motion.velocity.y = 120;
						styx.state = KILL_TRIGGER;
					}

					break;
				
				case KILL_TRIGGER:					
					if( motion.y > 510 || motion.x < 75 )
					{				
						motion.acceleration.y = 0;
						motion.velocity.y = 0;
						
						if( LOOP < 5 )
						{
							nextNode = node.previous as StyxNode;
							prevNode = nextNode.previous as StyxNode;
							prevNode.sleep.sleeping = false;
							prevNode.styx.state = SPAWN;
							LOOP++;
						}
						else
						{
							finished.dispatch();
						}
						
						styx.visual.alpha = 0;
						sleep.sleeping = true;
					}
					break;
			}
		}
		
		private function createSplash( node:StyxNode ):void
		{
			var styx:StyxComponent = node.styx;	
			var motion:Motion = node.motion;
			var audio:Audio = node.audio;
			
			audio.playCurrentAction( SPLASH );
			
			var emitter:Emitter2D = styx.splashEmitter;
			emitter.x = motion.x;
			emitter.y = motion.y + 50;
			
			emitter.start();
		}
		
		public var finished:Signal;
	
		private var LOOP:int 			=			0;
		private var BOAT_MOTION:Motion;
		private var HALF_WIDTH:Number;
		
		private var SPLASH_STALAC_POINT:int =		400;
		
		private var SHAKE_STALAC_POINT:int =		400;
		private var DROP_STALAC_POINT:int = 		150;
		private var KILL_STALAC_POINT:int =			500;
		
		private var SOUL_DIVE_POINT:int = 			150;
		private var SOUL_DIVE_SPEED:int = 			200;
		
		
		private const RANDOM:String	=				"random";
		
		private const CROC_ATTACK:int =				275;
		private const CROC_PAN_SPEED:int = 			-100;
		private const SOUL_VELOCITY:Number =		-100;
		private const CROC_ATTACK_VELOCITY:int =	-150;
		
		////////// NEW LABELS
		private const SPAWN:String			=			"spawn";
		private const TRIGGER:String		= 			"trigger";
		private const BEGIN_ATTACK:String		=		"begin_attack";
		private const EDIT_ATTACK:String		=		"edit_attack";
		private const END_ATTACK:String		=			"end_attack";
		private const KILL_TRIGGER:String	=			"kill_trigger";
		private const SPLASH:String			=			"splash";
	}
}