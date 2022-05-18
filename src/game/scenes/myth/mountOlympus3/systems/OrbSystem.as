package game.scenes.myth.mountOlympus3.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.data.motion.time.FixedTimestep;
	import game.scenes.myth.mountOlympus3.bossStates.OrbsState;
	import game.scenes.myth.mountOlympus3.bossStates.ZeusState;
	import game.scenes.myth.mountOlympus3.components.Orb;
	import game.scenes.myth.mountOlympus3.nodes.CloudCharacterStateNode;
	import game.scenes.myth.mountOlympus3.nodes.OrbNode;
	import game.scenes.myth.mountOlympus3.nodes.ZeusStateNode;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	import game.util.TweenUtils;
	
	public class OrbSystem extends GameSystem
	{
		private const HIT:String =		"hit";
		private const SPAWN:String = 	"spawn";
		private const SHOOT:String = 	"shoot";
		
		// global nodes
		private var _playerNode:CloudCharacterStateNode;
		private var _zeusNode:ZeusStateNode;
		
		public function OrbSystem()
		{
			super( OrbNode, nodeUpdate );
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			var playerNode:NodeList = systemManager.getNodeList( CloudCharacterStateNode );
			var zeusNode:NodeList = systemManager.getNodeList( ZeusStateNode );
			
			_playerNode = playerNode.head as CloudCharacterStateNode;
			_zeusNode = zeusNode.head as ZeusStateNode;
			
			super.addToEngine( systemManager );
		}
				
		private function nodeUpdate(node:OrbNode, time:Number):void
		{
			var orb:Orb = node.orb;
			var state:OrbsState = _zeusNode.fsmControl.getState( "orbs" ) as OrbsState;
			
			if( orb.timer > orb.duration && orb.state != Orb.END && orb.state != Orb.OFF )
			{
				orb.state = Orb.END;
			}
			
			switch( orb.state ) 
			{
				case Orb.OFF:				
					if( _zeusNode.boss.orbEnd )
					{
						_zeusNode.boss.orbEnd = false;
						_zeusNode.spatial.rotation = 0;
						
						state.setInvincible( false );
						
						ZeusState(_zeusNode.fsmControl.state).moveToNext();
					}
					break;
				
				case Orb.SPAWN:
					
					node.audio.playCurrentAction( SPAWN );
					node.display.visible = true;
					node.motion.zeroMotion();
					orb.orbitStep = -orb.startOrbitStep;
					node.spatial.x = orb.orbitTarget.x + orb.radius*Math.sin(orb.orbitStep);
					node.spatial.y = orb.orbitTarget.y - orb.radius*Math.cos(orb.orbitStep);
					orb.state = Orb.ORBIT;
					node.hazard.active = true;
					_zeusNode.boss.activeOrbs++;
					break;
	
				case Orb.ORBIT:
					orbit(node);
					if( orb.orbitStep > 0 )
					{
						orb.orbitStep = 0;	// try to normalize the pattern
						orb.state = Orb.FULL_ORBIT;
						
						var next:OrbNode = node.next as OrbNode;
						if( next )
						{
							next.orb.state = Orb.SPAWN;
							next.sleep.sleeping = false;
						}
					}
					break;
					
				case Orb.FULL_ORBIT:
					orbit(node);
					break;

				case Orb.HOME:
					orb.timer ++;
					homing(node);
					break;
				
				case Orb.DRIFT:
					orb.timer ++;
					drift(node);
					break;
					
				case Orb.END:
					orb.timer = 0;
					end(node);					
					break;
			}
		}

		private function end( node:OrbNode ):void
		{
			node.display.visible = false;
			node.orb.state = Orb.OFF;
			node.hazard.active = false;
			
			node.spatial.x = -100;
			node.spatial.y = -100;
			node.motion.zeroMotion();

			_zeusNode.boss.activeOrbs--;
			if( _zeusNode.boss.activeOrbs == 0 )
			{
				_zeusNode.boss.orbEnd = true;
			}
		}		

		
		private function drift( node:OrbNode ):void
		{
			checkHit( node );
		}
		
		private function orbit( node:OrbNode ):void
		{
			var orb:Orb = node.orb;

			orb.orbitStep += orb.increment;
			node.motion.x = orb.orbitTarget.x + orb.radius*Math.sin(orb.orbitStep);
			node.motion.y = orb.orbitTarget.y - orb.radius*Math.cos(orb.orbitStep);
			
			if( orb.orbitStep >= 3 * Math.PI )
			{
				node.audio.playCurrentAction( SHOOT );
				orb.state = Orb.HOME;
			}
		}
		
		private function homing( node:OrbNode ):void
		{
			if( node.orb.timer > 100 )
			{
				node.orb.state = Orb.DRIFT;
			}

			var motion:Motion = node.motion;
			var dist:Number = GeomUtils.dist( motion.x, motion.y, _playerNode.spatial.x, _playerNode.spatial.y );
			var dx:Number =_playerNode.motion.x - motion.x;
			var dy:Number = _playerNode.motion.y - motion.y;			
			
			// controls the 'stickyness' of the homing
			dist = 30 / dist;
			
			// accelerate at target
			motion.velocity.x = 0.98 * ( motion.velocity.x + dist * dx );
			motion.velocity.y = 0.98 * ( motion.velocity.y + dist * dy );			

			checkHit( node );
		}
		
		private function checkHit( node:OrbNode ):void
		{
			if( node.hazard.collided )
			{
				node.hazard.collided = false;
				node.audio.playCurrentAction( HIT );
				node.orb.state = Orb.END;
			}
		}
		
		/*
		private function electrify( node:OrbNode, active = true ):void
		{
		var display:Display = node.electrify.shockDisplay; 
		var electrify:ElectrifyComponent = node.electrify;
		var number:int;
		
		if( active )
		{
		TweenUtils.globalTo(group, display, 0.5, { alpha : 0.9 });
		}
		
		else
		{
		for( number = 0; number < electrify.sparks.length; number++ )
		{
		electrify.sparks[ number ].graphics.clear();
		}
		
		TweenUtils.globalTo(group, display, 0.4, { alpha : 1 });
		}
		
		electrify.on = active;
		}
		*/
	}
}