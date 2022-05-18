package game.systems.entity
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Camera;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.MotionMaster;
	import game.components.motion.Looper;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.hit.LooperHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;
	
	public class LoopingObjectSystem extends GameSystem
	{
		public function LoopingObjectSystem()
		{
			super( LooperHitNode, updateNode, nodeAdded );
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			_camera = group.shellApi.camera.camera;
			_head = systemManager.getNodeList( LooperHitNode ).head as LooperHitNode;
			
			var player:Entity = group.shellApi.player;
			_motionMaster = player.get( MotionMaster );
			
			wakeSignal = new Signal( LooperHitNode );
			
			super.addToEngine( systemManager );
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function nodeAdded( node:LooperHitNode ):void
		{
			node.looperHit.startMotion( node.motion );
		}
		
		public function updateNode( node:LooperHitNode, time:Number ):void
		{
			var spatial:Spatial = node.spatial;
			var looper:Looper = node.looperHit;
			var motion:Motion = node.motion;
			var buffer:Number;
			
			if( looper.linkedToTiles || looper.firstLinkCheck )
			{
				if( motion.velocity.x != 0 )
				{
						// DEFAULT TO THE WIDTH OF THE HIT, UNLESS A VALUE IS SPECIFIED IN XML
					buffer = ( looper.visualWidth ) ? looper.visualWidth : spatial.width;
						// SYNC WITH PLAYER'S MOTION MASTER COMPONENT
					if( _motionMaster )
					{
						if( motion.velocity.x != _motionMaster.velocity.x )
						{
							motion.velocity.x = _motionMaster.velocity.x;
						}
					}
					
						// WE ONLY WANT TO DO THE WAKE LOGIC IF NOT A SEGMENT LOOPER
					if( !looper.isSegment )
					{
						if( motion.velocity.x > 0 )
						{
							if( motion.x > _camera.areaWidth + buffer )
							{
								wakeNext( node );
							}
						}
						else
						{
							if( motion.x < -buffer )
							{
								wakeNext( node );
							}
						}
					}
				}
				
					// WE ONLY WANT TO DO THE WAKE LOGIC IF NOT A SEGMENT LOOPER
				else
				{
						// DEFAULT TO THE HEIGHT OF THE HIT, UNLESS A VALUE IS SPECIFIED IN XML
					buffer = ( looper.visualHeight ) ? looper.visualHeight : spatial.height;
						// SYNC WITH PLAYER'S MOTION MASTER COMPONENT IF THERE IS ONE
					if( _motionMaster )
					{
						if( motion.velocity.y != _motionMaster.velocity.y )
						{
							motion.velocity.y = _motionMaster.velocity.y;
						}
					}
					
					if( !looper.isSegment )
					{
						if( motion.y > 0 )
						{
							if( motion.y > _camera.areaHeight + buffer )
							{
								wakeNext( node );
							}
						}
						else
						{
							if( motion.y < -buffer )
							{
								wakeNext( node );
							}
						}
					}
				}
				
				if( !looper.linkedToTiles )
				{
					looper.firstLinkCheck = false;
				}
			}
		}
		
		
		private function wakeNext( node:LooperHitNode ):void
		{
			var looper:Looper = node.looperHit;
			var nextNode:LooperHitNode = node.next;
			var nextMotionValue:Point;
			var buffer:Number;
			
			do
			{
				if( !nextNode )
				{
					nextNode = _head;
					if(nextNode.looperHit.isLast)
						nextNode = nextNode.next;
				}
				if( nextNode.looperHit.inactive )
				{
					nextNode = nextNode.next;
				}
				if(nextNode)
				{
					if(nextNode.looperHit.isLast)
						nextNode = nextNode.next;
				}
				if(Math.abs(_motionMaster._distanceX / _motionMaster.goalDistance) >= .91)
				{
					var nodeList:NodeList = systemManager.getNodeList(LooperHitNode);
					for(var lnode:LooperHitNode = nodeList.head; lnode; lnode=lnode.next)
					{
						if(lnode.looperHit.isLast)
						{
							nextNode = lnode;
							nextNode.spatial.y = group.shellApi.currentScene.sceneData.bounds.bottom;
							nextNode.motion.velocity.x = node.motion.velocity.x * 2;
						}
					}
				}
			}while( !nextNode || nextNode.looperHit.inactive )
			
			if( _motionMaster )
			{
				nextMotionValue = _motionMaster.velocity;
			}

			if( nextNode.motion.velocity.x != 0 )
			{
					// DEFAULT TO THE WIDTH OF THE HIT, UNLESS A VALUE IS SPECIFIED IN XML
				buffer = ( nextNode.looperHit.visualWidth ) ? nextNode.looperHit.visualWidth : nextNode.spatial.width;
				
				if( nextNode.motion.velocity.x > 0 )
				{
					nextNode.spatial.x = -buffer;
				}
				else
				{
					nextNode.spatial.x = _camera.areaWidth + buffer;
				}
				
					// SET THE VELOCITY OF THE NEXT NODE TO THE VELOCITY OF THE CURRENT NODE
					// IF THERE IS A MOTION MASTER, SET IT TO THAT
				if( !nextMotionValue )
				{
					nextMotionValue = new Point( node.motion.velocity.x, 0 );
				}
				nextNode.motion.velocity.x = nextMotionValue.x;//node.motion.velocity.x;
			}
			else
			{
					// DEFAULT TO THE HEIGHT OF THE HIT, UNLESS A VALUE IS SPECIFIED IN XML
				buffer = ( nextNode.looperHit.visualHeight ) ? nextNode.looperHit.visualHeight : nextNode.spatial.height;
				
				if( nextNode.motion.velocity.y > 0 )
				{
					nextNode.spatial.y = -buffer;
				}
				else
				{
					nextNode.spatial.y = _camera.areaHeight + buffer;
				}
				
					// SET THE VELOCITY OF THE NEXT NODE TO THE VELOCITY OF THE CURRENT NODE
					// IF THERE IS A MOTION MASTER, SET IT TO THAT
				if( !nextMotionValue )
				{
					nextMotionValue = new Point( 0, node.motion.velocity.y );
				}
				nextNode.motion.velocity.y = node.motion.velocity.y;
			}
			
			// RESET FLAGS AND TOGGLE SLEEPS
			node.sleep.sleeping = true;
//			node.looperHit.collided = false;
			nextNode.sleep.sleeping = false;
			
			wakeSignal.dispatch( nextNode );
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( LooperHitNode );
			_head = null;
			
			super.removeFromEngine( systemManager );
		}
	
		public var wakeSignal:Signal;
		private var _camera:Camera;
		private var _head:LooperHitNode;
		private var _motionMaster:MotionMaster;
	}
}