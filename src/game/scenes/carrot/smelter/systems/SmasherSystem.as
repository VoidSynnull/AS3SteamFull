package game.scenes.carrot.smelter.systems
{	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.TargetEntity;
	import game.scenes.carrot.smelter.components.Smasher;
	import game.scenes.carrot.smelter.nodes.SmasherNode;
	import game.systems.GameSystem;
	
	import org.osflash.signals.Signal;
	
	public class SmasherSystem extends GameSystem
	{			
		public function SmasherSystem()
		{
			_squished = new Signal();
			_unsquished = new Signal();
			super( SmasherNode, updateNode );
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			super.addToEngine(systemManager);
			
			_playerMotion = group.shellApi.player.get( Motion );
			_playerSpatial = group.shellApi.player.get( Spatial );
			_motionControl = group.shellApi.player.get( MotionControl );
			_targetEntity = group.shellApi.player.get( TargetEntity );
			
			_playerEdge = group.shellApi.player.get( Edge );
		}
		
		private function updateNode( node:SmasherNode, time:Number ):void
		{
			var smasher:Smasher = node.smasher;
			
			var capSpatial:Spatial = smasher.capSpatial;
			var capMotion:Motion = smasher.capMotion;
			var wallMotion:Motion = smasher.wallMotion;
			var wallSpatial:Spatial = smasher.wallSpatial;
			
			smasher = node.smasher;
			
//			cap = smasher.cap;
//			wall = smasher.wall;
			
//			capSpatial = smasher.capSpatial;
//			wallSpatial = smasher.wallSpatial;
			
			switch( smasher.state )
			{
				case smasher.START_DOWN:
					if( wallSpatial.scaleY < MAX_WALL_SCALE )
					{
						capMotion.y = 5; //+= CAP_SCALE_STEP;
						wallSpatial.scaleY += WALL_SCALE_STEP;
					}
					else
					{
						capSpatial.y = CAP_DOWN_Y;
						wallSpatial.scaleY = MAX_WALL_SCALE;
					}
					
					checkPlayer( wallMotion, capMotion );
					break;
				
				case smasher.PAUSE_DOWN:
					capMotion.y = CAP_DOWN_Y;
					wallSpatial.scaleY = MAX_WALL_SCALE;		
					
					if( !_hitFlag )
					{
						checkPlayer( wallMotion, capMotion );
					}
					else
					{
						_playerSpatial.scaleY = .05;	
					}
					haltPlayerMove( wallMotion );
					break;
					
				case smasher.START_UP:
					if( _hitFlag )
					{
						_unsquished.dispatch();
						_hitFlag = false;
					}
					
					if( wallSpatial.scaleY > MIN_WALL_SCALE )
					{	
						capMotion.y -= CAP_SCALE_STEP;
						wallSpatial.scaleY -= WALL_SCALE_STEP;
					}
					else
					{
						capMotion.y = CAP_UP_Y;
						wallSpatial.scaleY = MIN_WALL_SCALE;
					}
					break;
					
				case smasher.PAUSE_UP:
					capMotion.y = CAP_UP_Y;
					wallSpatial.scaleY = MIN_WALL_SCALE;
					break;
			}
		}
	
		private function checkPlayer( wallMotion:Motion, capMotion:Motion ):void
		{			
			if( wallMotion.x - WALL_WIDTH < _playerMotion.x && _playerMotion.x < wallMotion.x + WALL_WIDTH && _playerSpatial.y > 300 )
			{
				if( _playerMotion.y < capMotion.y )
				{
					_playerMotion.y = capMotion.y;
					
					if(( _playerEdge.rectangle.bottom + _playerMotion.y ) > CAP_DOWN_Y )
					{
						if( !_hitFlag )
						{
							_squished.dispatch();
						}
						
						_motionControl.lockInput = true;	//TODO :: Need to check onthis.
						_motionControl.moveToTarget = false;
						_motionControl.inputActive = false;
						
						_targetEntity.active = false;
						
//						CharUtils.lockControls( super.player, false, false );
						if( _playerSpatial.scaleY > .05 )
						{
							_playerSpatial.scaleY -= PLAYER_SCALE_STEP;
						}
						_hitFlag = true;
					}
				}
			}	
		}
		
		private function haltPlayerMove( wallMotion:Motion ):void
		{
			if( _playerMotion.y > 300 )
			{
				if( wallMotion.x + WALL_WIDTH - 20 < _playerMotion.x && _playerMotion.x < wallMotion.x + WALL_WIDTH + 30  )
				{
					_playerMotion.x = wallMotion.x + WALL_WIDTH + 30;
				}
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( SmasherNode );
			_nodes = null;
		}
		
		private var _targetEntity:TargetEntity;
		private var _motionControl:MotionControl
		
		private var _nodes:NodeList;
		private var _hitFlag:Boolean = false; 
		private var _playerMotion:Motion;
		private var _playerSpatial:Spatial;
		private var _playerEdge:Edge;
		
		public var _squished:Signal;
		public var _unsquished:Signal;
		
		private static const CAP_UP_Y:uint = 500;
		private static const CAP_DOWN_Y:uint = 730;
		private static const CAP_SCALE_STEP:uint = 20;
		
		private static const MIN_WALL_SCALE:Number = .21;
		private static const MAX_WALL_SCALE:uint = 1;
		private static const WALL_SCALE_STEP:Number = .1;
		private static const WALL_WIDTH:uint = 80;
	
		private static const PLAYER_SCALE_STEP:Number = .05;
		private static const OFFSET_STEP:Number = 5.1;
	}
}