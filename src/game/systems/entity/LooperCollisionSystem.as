package game.systems.entity
{
	import flash.display.DisplayObject;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	
	import game.components.Emitter;
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.LooperCollisionNode;
	import game.nodes.hit.LooperHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class LooperCollisionSystem extends GameSystem
	{
		public function LooperCollisionSystem()
		{
			super( LooperCollisionNode, updateNode );
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.resolveCollisions;
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			super.addToEngine( systemManager );
			_hits = systemManager.getNodeList( LooperHitNode );
		}
		
		public function updateNode( collisionNode:LooperCollisionNode, time:Number ):void
		{
			var entity:Entity;
			var hitNode:LooperHitNode;
			var collisionDisplayObject:DisplayObject;
			var hitDisplay:Display;
			var hitEdge:Edge;
			var collisionEdge:Edge;
			var isHit:Boolean = false;
			var newHit:Boolean = false;
			
//			collisionNode.currentHit.hit = null;
			
			for( hitNode = _hits.head; hitNode; hitNode = hitNode.next )
			{
					// IF HIT IS SLEEPING, SKIP TO THE NEXT
				if( EntityUtils.sleeping( hitNode.entity ))
				{
					continue;
				}
				

				hitDisplay = hitNode.display;
				
				collisionDisplayObject = collisionNode.display.displayObject;
				if( collisionNode.display.displayObject.getChildByName( "hit" ))
				{
					collisionDisplayObject = collisionNode.display.displayObject.getChildByName( "hit" );
				}
				
				if( hitDisplay.displayObject.hitTestObject( collisionDisplayObject ))
				{
					if(hitNode.looperHit.visualEntity)
					{
						if(!Display(hitNode.looperHit.visualEntity.get(Display)).visible)
						{
							//trace("HERESEY YOU SHOULD NOT GET HIT BY INVISIBLE OBJECTS!");
							continue;
						}
					}
					newHit = hit( collisionNode, hitNode );
					
					if( newHit == false && hitNode.looperHit.alwaysOn )
					{
						for each( entity in hitNode.looperHit.colliders )
						{
							if( entity == collisionNode.entity )
							{
								hitNode.looperHit.colliders = removeFromVector( entity, hitNode.looperHit.colliders );
							}
						}
					}
					else
					{
						isHit = newHit;
					}
					continue;
				}
				
				if( hitDisplay.displayObject.hitTestObject( collisionDisplayObject ))
				{
					newHit = hit( collisionNode, hitNode );
					
					if( newHit == false && hitNode.looperHit.alwaysOn )
					{
						for each( entity in hitNode.looperHit.colliders )
						{
							if( entity == collisionNode.entity )
							{
								hitNode.looperHit.colliders = removeFromVector( entity, hitNode.looperHit.colliders );
							}
						}
					}
					else
					{
						isHit = newHit;
					}
					continue;
				}
				else
				{
					// TODO: MAKE THIS A LIST OF ENTITIES CURRENTLY HITTING IT AND CHECK IF THIS ENTITY IS IN THE LIST
	//				hitNode.looperHit.collided = false;
					for each( entity in hitNode.looperHit.colliders )
					{
						if( entity == collisionNode.entity )
						{
							hitNode.looperHit.colliders = removeFromVector( entity, hitNode.looperHit.colliders );
						}
					}
				}
			}
			
//			collisionNode.currentHit.hit = null;
			
			// TODO: MAKE THIS A LIST OF ENTITIES CURRENTLY HITTING IT AND CHECK IF THIS ENTITY IS IN THE LIST
			if( !isHit )
			{
				collisionNode.collider.isHit = false;
				collisionNode.currentHit.hit = null;
			}
			
		}
		
			// HIT LOGIC
		
		private function hit( collisionNode:LooperCollisionNode, hitNode:LooperHitNode ):Boolean
		{
			var emitter:Emitter;
			var entity:Entity;
			var newHit:Boolean = true;
			
			trace( "collided with " + hitNode.id.id );
			
//			if(( !collisionNode.collider.isHit || collisionNode.currentHit.hit != hitNode.entity ))// && ( !hitNode.looperHit.collided ))
//			{
				// is this 
				for each( entity in hitNode.looperHit.colliders )
				{
					if( collisionNode.entity == entity )
					{
						newHit = false;
					}
				}
				
				if( newHit || hitNode.looperHit.alwaysOn )
				{
					trace( "have not already hit " + hitNode.id.id );
//					if( collisionNode )
//					{
					// TODO :: should store the type in the looper hit component
					if( hitNode.looperHit.type )
					{
						collisionNode.collider.collisionType = hitNode.looperHit.type;
						collisionNode.collider.hitSpatial = hitNode.spatial;
						collisionNode.collider.hitDisplay = hitNode.display;
						collisionNode.collider.hitEdge = hitNode.edge;
						collisionNode.collider.hitMotion = hitNode.motion;
						
	//							collisionNode.collider.isHit = true;
						
	//					var boundsRect:Rectangle = hitNode.display.displayObject.getBounds( hitNode.display.displayObject );
	//					var localToGlobal:Point = hitNode.display.displayObject.localToGlobal( new Point( hitNode.spatial.x, hitNode.spatial.y ));
	//					var globalToLocal:Point = hitNode.display.displayObject.localToGlobal( new Point( collisionNode.spatial.x, collisionNode.spatial.y ));
						
						if( collisionNode.player && collisionNode.fsmControl.check( collisionNode.fsmControl.state.type ))
						{
	//								hitNode.looperHit.collided = true;
							hitNode.looperHit.colliders.push( collisionNode.entity );
							
							if( hitNode.hitAudioData )
							{
								collisionNode.currentHit.hit = hitNode.entity;
								EntityUtils.playAudioAction(collisionNode.hitAudio, hitNode.hitAudioData);
							}
							if (collisionNode.collider.triggerFunction)
								collisionNode.collider.triggerFunction(hitNode.entity);
							if( hitNode.looperHit.emitters )
							{
								for each( emitter in hitNode.looperHit.emitters )
								{
									emitter.start = true;
								}
							}
						}
						
						// ASSUME NON-PLAYERS WILL ALWAYS TRIGGER IT
						else if( !collisionNode.player )
						{
							if (collisionNode.collider.triggerFunction)
								collisionNode.collider.triggerFunction(collisionNode.id.id);
							hitNode.looperHit.colliders.push( collisionNode.entity );
							collisionNode.currentHit.hit = hitNode.entity;
							EntityUtils.playAudioAction(collisionNode.hitAudio, hitNode.hitAudioData);
							
							if( hitNode.looperHit.emitters )
							{
								for each( emitter in hitNode.looperHit.emitters )
								{
									emitter.start = true;
								}
							}
						}
					}
				}
				else
				{
					trace( collisionNode.id.id + " already hit : " + hitNode.id.id );
				}
//			}
			
			return newHit;
		}
		
		
		private function removeFromVector( entity:Entity, vector:Vector.<Entity> ):Vector.<Entity>
		{
			var newVector:Vector.<Entity> = new Vector.<Entity>;
			var targetPosition:uint = vector.indexOf( entity );
			var vectorLength:uint = vector.length;
			
			for( var number:uint = 0; number < vectorLength; number ++ )
			{
				if( number != targetPosition )
				{
					newVector.push( vector.pop());
				}
			}
			
			return newVector;
		}
		
		private var _hits:NodeList;
	}
}