package game.scenes.myth.hydra.systems
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Hazard;
	import game.components.timeline.Timeline;
	import game.scenes.myth.hydra.components.HydraControlComponent;
	import game.scenes.myth.hydra.components.HydraHeadComponent;
	import game.scenes.myth.hydra.components.HydraNeckComponent;
	import game.scenes.myth.hydra.nodes.HydraHeadNode;
	import game.systems.GameSystem;
	
	
	public class HydraHeadSystem extends GameSystem
	{
		public function HydraHeadSystem( hydraControl:HydraControlComponent )
		{
			_hydraControl = hydraControl;
			super( HydraHeadNode, updateNode );
			super.fixedTimestep = 1/30;
		}
				
		private function updateNode( node:HydraHeadNode, time:Number ):void
		{
			var audio:Audio = node.audio;
			var spatial:Spatial = node.spatial;
			var neck:HydraNeckComponent = node.neckComponent;
			var head:HydraHeadComponent = node.headComponent;
			
			var headNumber:Number = head.headNumber;
			
			var hitDisplay:Display; 
			
			var deltaX:Number;
			var timeline:Timeline;
			
			
			/*******************************
			 * 	   MAIN SYSTEM LOOP
			 * *****************************/
			if( !_hydraControl.defeated )
			{
				if( node.id.id == "hit0" && Math.random() * 100 > 99 )
				{
					audio.playCurrentAction( IDLE );
				}
				
				switch( head.state )
				{
					case DEAD:
//						neck.time ++;
//						if( neck.time > 1200 )
//						{
//							head.state = NORMAL;
//							head.dead = false;
//							Timeline( head.head.get( Timeline )).gotoAndStop( NORMAL );
//							_hydraControl.deadHeads --;
//							_hydraControl.activeHeads[ head.headNumber ] = true;
//						}
						break;
				
					case NORMAL:
						neck.time += time;
						moveNeck( node, time );
						
						if( !_hydraControl.isAttacking )
						{
							_hydraControl.idleTimer ++;
							
							if( _hydraControl.idleTimer > 90 )
							{
								var attackHead:int;
								
								do
								{
									attackHead = Math.round( Math.random() * 4 );
								}
								while( !_hydraControl.activeHeads[ attackHead ])
									
								_hydraControl.isAttacking = true;
								_hydraControl.attackHead = attackHead;
								_hydraControl.idleTimer = 0;
							}
						}
						
						else
						{
							if( head.headNumber == _hydraControl.attackHead )
							{
								head.state = SEEK;
							}
						}
						break;
					
					case SEEK:
						deltaX = playerSpatial.x - neck.anchor.x;
						if( !( deltaX < 40  || deltaX > 660 ))
						{
							head.attackTargetX = playerSpatial.x;
							head.attackTargetY = playerSpatial.y;
							
							head.seekTargetX = spatial.x - ATTACK_OFFSET_X;
							head.seekTargetY = spatial.y - ATTACK_OFFSET_Y;
							
							timeline = head.headTimeline;
							timeline.gotoAndStop( NOTICE );
							seekTo( node );
							
							head.state = NOTICE;
							audio.playCurrentAction( NOTICE );
						}
						else
						{
							neck.time += time;
												
							if( neck.time > 3 )
							{
								head.state = NORMAL;
								neck.time = 0;
								_hydraControl.isAttacking = false;
							}
							
							moveNeck( node,time );
						}
						break;
					
					case NOTICE:
						head.stretch = true;
						neckThrust( node, time );
						break;
					
					case SHAKE:
						head.stretch = false;
						head.attack = false;
						
						switch( head.headTimeline.currentFrameData.label )
						{	
							case NOTICE:
								head.stretch = true;	
								break;
							case HUNGRY:
								head.attack = true;
								break;
							case HIT:
								if( !head.hit )
								{
									head.removeHit();
									head.attack = true;
									head.hit = true;
								}
								break;
						}
						
						shakeHead( node, time );
						break;
					
					case HUNGRY:
						head.seekTargetX = head.attackTargetX;
						head.seekTargetY = head.attackTargetY;
						
						seekTo( node );
						head.state = ATTACK;
						audio.playCurrentAction( ATTACK );
						head.hittable = true;
						break;
					
					case ATTACK:
						head.attack = true;
						neckThrust( node, time );
						break;
					
					case RESET:
						head.attack = false;
						_hydraControl.isAttacking = false;
						resetHead( node, time );
						break;
					
					case KILL:
						killHead( node );
						break;
					
					case FALL:
						head.dead = true;
						headFall( node, time );
						break;
				}
				
				/*******************************
				 * 	  CAN ATTACK EXPOSED HEAD
				 * *****************************/
				hitDisplay = node.display;
				if( head.hittable )
				{
					hitDisplay = head.hitDisplay;
						
					if( playerMotion.velocity.y > 0 )
					{
						if( hitDisplay.displayObject.hitTestObject( playerDisplay ))
						{
							setHit( node );
							audio.playCurrentAction( HIT );
						}
					}
				}
		
				/*******************************
				 * 	     DEFEATED HYDRA
				 * *****************************/
				if( _hydraControl.deadHeads == 5 )
				{
					group.shellApi.triggerEvent( "hydra_defeated" );
					_hydraControl.defeated = true;
				}
			}
			
			else
			{
				switch( head.state )
				{
					case KILL:
						killHead( node );
						break;
					
					case FALL:
						head.dead = true;
						headFall( node, time );
						break;
					
					case DEAD:
						break;
				}
			}
		}
		
		/*******************************
		 * 	  NORMAL HEAD MOVEMENT
		 * *****************************/
		private function moveNeck( node:HydraHeadNode, time:Number ):void
		{
			var number:Number;
			var neck:HydraNeckComponent = node.neckComponent;
			var currentJoint:Spatial = neck.joints[ 0 ];
			var lastJoint:Spatial;
			var ghostJoint:Spatial = neck.joints[ 0 ];
			
			neck.pointTime[ 0 ] += time;
			currentJoint.rotation = neck.angle + Math.sin( node.neckComponent.pointTime[ 0 ] );
			currentJoint.x = neck.segLength * Math.cos( currentJoint.rotation );
			currentJoint.y = neck.segLength * Math.sin( currentJoint.rotation );
			
			ghostJoint.rotation = currentJoint.rotation;
			ghostJoint.x = currentJoint.x;
			ghostJoint.y = currentJoint.y;
			
			for( number = 1; number < node.neckComponent.joints.length; number ++ )
			{
				lastJoint = currentJoint;
				currentJoint = neck.joints[ number ];
				ghostJoint = neck.ghostJoints[ number ];
				neck.pointTime[ number ] += time * ( number + 1 );
				
				currentJoint.rotation = neck.angle + .4 * Math.sin( neck.pointTime[ number ] );
				currentJoint.x = lastJoint.x + neck.segLength * Math.cos( currentJoint.rotation );
				currentJoint.y = lastJoint.y + neck.segLength * Math.sin( currentJoint.rotation );
				
				ghostJoint.rotation = currentJoint.rotation;
				ghostJoint.x = currentJoint.x;
				ghostJoint.y = currentJoint.y;
			}
			
			drawNeck( node );
		}
		
		private function drawNeck( node:HydraHeadNode ):void 
		{
			var number:Number;
			var head:HydraHeadComponent = node.headComponent;
			var neck:HydraNeckComponent = node.neckComponent;
			var currentJoint:Spatial;
			var nextJoint:Spatial;
			var length:Number = neck.joints.length - 1;
					
			if( head.stretch )
			{
				length --;
			}
			if( head.dead )
			{
				length -= 2;
			}
			
			var clip:MovieClip = neck.anchor;
			
			clip.graphics.clear();
			clip.graphics.lineStyle( BORDER_THICKNESS, BORDER_COLOR );
			clip.graphics.moveTo( 0, 0 );
			
			for( number = 0; number < length; number ++ )
			{
				currentJoint = neck.joints[ number ];
				nextJoint = neck.joints[ number + 1 ];
				
				clip.graphics.curveTo( currentJoint.x, currentJoint.y, ( currentJoint.x + nextJoint.x ) / 2, ( currentJoint.y + nextJoint.y ) / 2 );
			}
			
			clip.graphics.lineStyle( THICKNESS, COLOR );
			clip.graphics.moveTo( 0, 0 );
			
			for( number = 0; number < length; number ++ )
			{
				currentJoint = neck.joints[ number ];
				nextJoint = neck.joints[ number + 1 ];
				
				clip.graphics.curveTo( currentJoint.x, currentJoint.y, ( currentJoint.x + nextJoint.x ) / 2, ( currentJoint.y + nextJoint.y ) / 2 );
			}
			
			moveHead( node );
		}
		
		private function moveHead( node:HydraHeadNode ):void 
		{
			var length:int = node.neckComponent.joints.length - 1;
			var head:HydraHeadComponent = node.headComponent;
			var neck:HydraNeckComponent = node.neckComponent;
			var yModifier:int = 0;
			var xModifier:int = 0;
			
			if( head.attack )
			{
				length --;
			}
			if( head.stretch )
			{
				length --;
				yModifier = 20;
				xModifier = -10;
			}
			if( head.dead )
			{
				length -= 2;
			}
			
			var endJoint:Spatial = neck.joints[ length ];
			var spatial:Spatial = node.spatial;
			var displaySpatial:Spatial = head.headSpatial;
			
			spatial.x = endJoint.x + neck.anchor.x + xModifier;
			spatial.y = endJoint.y + neck.anchor.y + yModifier;
			spatial.rotation = neck.angle + .4 * Math.sin( neck.pointTime[ 3 ] );
			displaySpatial.rotation = spatial.rotation;
			
			if( head.state == FALL )
			{
			 	displaySpatial.rotation = 90;	
			}
		}
		
		/*******************************
		 * 		ATTACK PREPARATION
		 * *****************************/
		private function seekTo( node:HydraHeadNode ):void
		{
			var number:Number;
			var head:HydraHeadComponent = node.headComponent;
			var neck:HydraNeckComponent = node.neckComponent;
			var currentJoint:Spatial;
			
			var deltaX:Number = ( head.seekTargetX - neck.anchor.x ) / neck.numPoints;
			var deltaY:Number = ( head.seekTargetY - neck.anchor.y ) / neck.numPoints;
			
			for( number = neck.stiffJoints.length - 1; number >= 0; number -- )
			{
				currentJoint = neck.stiffJoints[ number ];
				currentJoint.x = ( number + 1 ) * deltaX;
				currentJoint.y = ( number + 1 ) * deltaY;
			}
			
			neck.time = 0;
		}		
		
		private function shakeHead( node:HydraHeadNode, time:Number ):void
		{
			var number:Number;
			var head:HydraHeadComponent = node.headComponent;
			var neck:HydraNeckComponent = node.neckComponent;
			var currentJoint:Spatial;
			
			for( number = neck.joints.length - 1; number >= 0; number -- )
			{
				currentJoint = neck.joints[ number ];
				currentJoint.x = neck.stiffJoints[ number ].x - 4 + 8 * Math.random();
				currentJoint.y = neck.stiffJoints[ number ].y - 4 + 8 * Math.random();
			}
			
			drawNeck( node );
			
			neck.time -= time * 2;
			if( neck.time < 0 )
			{
				var currentLabel:String = head.headTimeline.currentFrameData.label;
				
				switch( currentLabel )
				{
					case NOTICE:
						head.headTimeline.gotoAndStop( HUNGRY );
						head.stretch = false;
						head.attack = true;
						head.state = HUNGRY;
						break;
					case HUNGRY:
						head.headTimeline.gotoAndStop( NORMAL );
						neck.time = 0;
						head.state = RESET;
					//	head.stretch = true;
					//	head.attack = false;
						head.hittable = false;
						break;
					case HIT:
						head.headTimeline.gotoAndStop( DEAD );
						computeFall( node );
						head.state = KILL;
						break;
				}
			}
		}
		
		/*******************************
		 * 		ATTACK LUNGE
		 * *****************************/
		private function neckThrust( node:HydraHeadNode, time:Number ):void
		{
			var number:Number;
			var head:HydraHeadComponent = node.headComponent;
			var neck:HydraNeckComponent = node.neckComponent;
			var currentJoint:Spatial;
			
			var modifier:Number = Math.sin( neck.time );
			var minus:Number = 1 - modifier;
			
			neck.time += time * 5;
			
			computeWave( node, time );
			
			for( number = neck.joints.length - 1; number >= 0; number -- )
			{
				currentJoint = neck.joints[ number ];
				
				currentJoint.x = modifier * neck.stiffJoints[ number ].x + minus * neck.ghostJoints[ number ].x;
				currentJoint.y = modifier * neck.stiffJoints[ number ].y + minus * neck.ghostJoints[ number ].y;				
			}
			
			drawNeck( node );
			
			if( neck.time >= ( Math.PI / 2 ))
			{
				for( number = 1; number < neck.stiffJoints.length; number ++ )
				{
					currentJoint = neck.stiffJoints[ number ];
					
					currentJoint.x = neck.joints[ number ].x;
					currentJoint.y = neck.joints[ number ].y; 
				}
				
				head.state = SHAKE;
			}
		}	
		
		/*******************************
		 * 	  SPATIAL CALCULATIONS
		 * *****************************/
		private function computeWave( node:HydraHeadNode, time:Number ):void 
		{
			var number:Number;
			var neck:HydraNeckComponent = node.neckComponent;
			var ghostJoint:Spatial = neck.ghostJoints[ 0 ];
			var lastJoint:Spatial;
			
			neck.pointTime[ 0 ] += time;
			ghostJoint.rotation = neck.angle + Math.sin( neck.pointTime[ 0 ]);
			ghostJoint.x = neck.segLength * Math.cos( ghostJoint.rotation );
			ghostJoint.y = neck.segLength * Math.sin( ghostJoint.rotation );
			
			for( number = 1; number < neck.ghostJoints.length; number ++ )
			{
				lastJoint = ghostJoint;
				ghostJoint = neck.ghostJoints[ number ];
				
				neck.pointTime[ number ] += time;
				ghostJoint.rotation = neck.angle + MAX * Math.sin( neck.pointTime[ number ]);
				ghostJoint.x = lastJoint.x + neck.segLength * Math.cos( ghostJoint.rotation );
				ghostJoint.y = lastJoint.y + neck.segLength * Math.sin( ghostJoint.rotation );
			}
		}
				
		/*******************************
		 * 	    HEAD KNOCKED OUT
		 * *****************************/
		private function computeFall( node:HydraHeadNode ):void
		{
			var number:int;
			var head:HydraHeadComponent = node.headComponent;
			var neck:HydraNeckComponent = node.neckComponent;
			var finalAngle:Number = .6 * Math.PI;
			var currentJoint:Spatial = neck.stiffJoints[ 0 ]
			var lastJoint:Spatial;
			
			var deltaAngle:Number = ( finalAngle - neck.angle ) / neck.stiffJoints.length;
			
			currentJoint.rotation = neck.angle;
			currentJoint.x = neck.segLength * Math.cos( neck.angle );
			currentJoint.y = neck.segLength * Math.sin( neck.angle );
			
			for( number = 1; number < neck.stiffJoints.length; number ++ )
			{
				lastJoint = currentJoint;
				currentJoint = neck.stiffJoints[ number ];
				
				currentJoint.rotation = neck.angle + number * deltaAngle;
				currentJoint.x = lastJoint.x + neck.segLength * Math.cos( neck.angle );
				currentJoint.y = lastJoint.y + neck.segLength * Math.sin( neck.angle );
			}
				
			neck.time = 0;
		}
		
		private function killHead( node:HydraHeadNode ):void
		{
			var number:int;
			var head:HydraHeadComponent = node.headComponent;
			var neck:HydraNeckComponent = node.neckComponent;
			var currentJoint:Spatial;
			var lastJoint:Spatial;
			
			var deltaAngle:Number = ( 0.6 * Math.PI - Math.PI / 8 ) / neck.joints.length;
			currentJoint = neck.ghostJoints[ 0 ];
			
			currentJoint.rotation = Math.PI / 8;
			currentJoint.x = neck.segLength * Math.cos( currentJoint.rotation );
			currentJoint.y = neck.segLength * Math.sin( currentJoint.rotation );
			
			for( number = 1; number < neck.ghostJoints.length; number ++ )
			{
				lastJoint = currentJoint;
				currentJoint = neck.ghostJoints[ number ];
				
				currentJoint.rotation = Math.PI / 8 + number * deltaAngle;
				currentJoint.x = lastJoint.x + neck.segLength * Math.cos( currentJoint.rotation );
				currentJoint.y = lastJoint.y + neck.segLength * Math.sin( currentJoint.rotation );
			}
			
			node.entity.remove( Hazard );
			
			head.stretch = false;
			head.attack = false;
			
			neck.time = 0;
			head.state = FALL;
		}
			
		private function headFall( node:HydraHeadNode, time:Number ):void	
		{
			var number:int;
			var head:HydraHeadComponent = node.headComponent;
			var neck:HydraNeckComponent = node.neckComponent;
			var currentJoint:Spatial;
			
			neck.time += time;
			
			var modifier:Number = Math.sin( neck.time );
			var minus:Number = 1 - modifier;
						
			for( number = neck.joints.length - 1; number >= 0; number -- )
			{
				currentJoint = neck.joints[ number ];
				
				currentJoint.x = modifier * neck.ghostJoints[ number ].x + minus * currentJoint.x;
				currentJoint.y = modifier * neck.ghostJoints[ number ].y + minus * currentJoint.y;
			}
			
			drawNeck( node );
			
			if( neck.time >= ( Math.PI ) / 2 )
			{
				head.state = DEAD;
				neck.time = 0;
				
				_hydraControl.activeHeads[ head.headNumber ] = false;
				_hydraControl.deadHeads ++;
				_hydraControl.isAttacking = false;
			}	
		} 
		
		/*******************************
		 * 	 RETURN TO NORMAL MOVEMENT
		 * *****************************/
		
		// Tween tendril back to standard motion, updating the movement
		// so the animation is smooth.
		private function resetHead( node:HydraHeadNode, time:Number ):void
		{
			var head:HydraHeadComponent = node.headComponent;
			var neck:HydraNeckComponent = node.neckComponent;
			var ghostJoint:Spatial
			var currentJoint:Spatial;
			var lastGhostJoint:Spatial;
			var lastJoint:Spatial;
			var number:int;
			
			neck.time += time;/// 10;
			var minus:Number = 1 - neck.time;
			neck.pointTime[ 0 ] += .1; 
			
			currentJoint = neck.joints[ 0 ];
			currentJoint.rotation = neck.angle + Math.sin( neck.pointTime[ 0 ]);
			
			ghostJoint = neck.stiffJoints[ 0 ];
			ghostJoint.x = neck.segLength * Math.cos( neck.angle );
			ghostJoint.y = neck.segLength * Math.sin( neck.angle );
			
			currentJoint.x = neck.time * ghostJoint.x + minus * currentJoint.x;
			currentJoint.y = neck.time * ghostJoint.y + minus * currentJoint.y;
			
			for( number = 1; number < neck.joints.length; number ++ )
			{
				lastJoint = currentJoint;
				lastGhostJoint = ghostJoint;
				currentJoint = neck.joints[ number ];
				ghostJoint = neck.stiffJoints[ number ];
				
				neck.pointTime[ number ] += .1;
				currentJoint.rotation = neck.angle + Math.sin( neck.pointTime[ number ] );
				
				ghostJoint.x = lastGhostJoint.x + neck.segLength * Math.cos( ghostJoint.rotation );
				ghostJoint.y = lastGhostJoint.y + neck.segLength * Math.sin( ghostJoint.rotation );
		
				currentJoint.x = neck.time * ghostJoint.x + minus * currentJoint.x;
				currentJoint.y = neck.time * ghostJoint.y + minus * currentJoint.y;
			}
			
			drawNeck( node );
			
			if( neck.time >= ( Math.PI ) / 6 )
			{
				head.state = NORMAL;
				head.stretch = false;
				head.attack = false;
				_hydraControl.isAttacking = false;
			}
		} 
		
		/*******************************
		 * 	  PLAYER LANDS ON HEAD
		 * *****************************/
		private function setHit( node:HydraHeadNode ):void
		{
			playerMotion.velocity.y = BOUNCE_Y;
			
			var neck:HydraNeckComponent = node.neckComponent;
			var head:HydraHeadComponent = node.headComponent;
			
			head.headTimeline.gotoAndStop( HIT );
			head.state = SHAKE;
			
			head.hittable = false;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			playerSpatial = group.shellApi.player.get( Spatial );
			playerMotion = group.shellApi.player.get( Motion );
			playerDisplay = group.shellApi.player.get( Display ).displayObject;
			
			super.addToEngine(systemManager);
		}
		
		private var _hydraControl:HydraControlComponent;
		
		private var playerSpatial:Spatial;
		private var playerMotion:Motion;
		private var playerDisplay:DisplayObject;
		
		private static const BASE_ROTATION:int = 50;
		private static const DEG_MODIFIER:Number = 3;
		private static const DEG_PER_RAD:Number = (180/Math.PI);
		private static const THICKNESS:Number = 38;
		private static const BORDER_THICKNESS:Number = 42;
//		private static const DELTA_T:Number = 1/30;
		private static const MAX:Number = .4;
		private static const COLOR:uint = 0x6fa696;
		private static const BORDER_COLOR:uint = 0x2b403a;
		
		private static const ATTACK_OFFSET_X:int = 10;
		private static const ATTACK_OFFSET_Y:int = 200;
		private static const BOUNCE_Y:int = -400;
		
		private static const NORMAL:String =	"normal";
		private static const RESET:String = 	"reset";
		private static const SEEK:String = 		"seek";
		private static const NOTICE:String = 	"notice";
		private static const SHAKE:String = 	"shake";
		private static const HUNGRY:String = 	"hungry";
		private static const ATTACK:String = 	"attack";
		private static const RETREAT:String =	"retreat";
		private static const HIT:String = 		"hit";
		private static const KILL:String = 		"kill";
		private static const FALL:String = 		"fall";
		private static const DEAD:String = 		"dead";
		private static const BITE:String		= "bite";
		private static const IDLE:String 		= "idle";
		
	}
}