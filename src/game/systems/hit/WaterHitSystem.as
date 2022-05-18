package game.systems.hit
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.Water;
	import game.components.motion.Edge;
	import game.creators.entity.EmitterCreator;
	import game.data.motion.time.FixedTimestep;
	import game.data.scene.hit.HitAudioData;
	import game.nodes.entity.collider.BitmapCollisionNode;
	import game.nodes.entity.collider.WaterCollisionNode;
	import game.nodes.hit.BitmapHitAreaNode;
	import game.nodes.hit.WaterBitmapHitNode;
	import game.nodes.hit.WaterHitNode;
	import game.particles.emitter.WaterSplash;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	
	public class WaterHitSystem extends GameSystem
	{
		public function WaterHitSystem()
		{
			super(WaterCollisionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_hits = systemManager.getNodeList(WaterHitNode);
			_bitmapHits = systemManager.getNodeList(WaterBitmapHitNode);
			_hitAreaNodes = systemManager.getNodeList(BitmapHitAreaNode);
			_hitAreaNode = _hitAreaNodes.head;
			
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			_hitAreaNode = null;
			_hitAreaNodes = null;
			_hits = null;
			_bitmapHits = null;
			
			systemManager.releaseNodeList(WaterCollisionNode);
			systemManager.releaseNodeList(WaterHitNode);
			systemManager.releaseNodeList(WaterBitmapHitNode);
			systemManager.releaseNodeList(BitmapCollisionNode);
			
			super.removeFromEngine(systemManager);
		}
		
		override public function update(time:Number):void
		{			
			if(_hitAreaNode == null)
			{
				_hitAreaNode = _hitAreaNodes.head;
			}
			else
			{
				super.update(time);
			}
		}
		
		private function updateNode(colliderNode:WaterCollisionNode, time:Number):void
		{				
			var waterCollider:WaterCollider = colliderNode.collider;
			var bitmapCollider:BitmapCollider = colliderNode.bitmapCollider;
			var hitNode:WaterHitNode;
			var bitmapHitNode:WaterBitmapHitNode;
			var hitDisplay:DisplayObjectContainer;
			
			if(bitmapCollider)
			{
				if(bitmapCollider.centerColor == 0)
				{
					for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
					{
						if( bitmapHitNode.hit.sceneWide )	// if scene wide hit, force water hit (probably want to set this different, not via hits. - Batd
						{
							waterCollider.entered = true;
							hitWater(colliderNode.motion.x, colliderNode.motion.y, -100, colliderNode, bitmapHitNode.entity, bitmapHitNode.hit, bitmapHitNode.hitAudioData);
							return;
						}
					}
				}
				else
				{
					for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
					{
						// TODO :: Actually want to check against bottom pixel, but that involves making water a platform hit. - Bard
						if(bitmapCollider.centerColor == bitmapHitNode.bitmapHit.color)
						{
							hitWater(colliderNode.motion.x, colliderNode.motion.y, getSurface(bitmapCollider), colliderNode, bitmapHitNode.entity, bitmapHitNode.hit, bitmapHitNode.hitAudioData);
							return;
						}
					}
				}
			}
			
			for(hitNode = _hits.head; hitNode; hitNode = hitNode.next)
			{
				if(EntityUtils.sleeping(hitNode.entity))
				{
					return;
				}
				
				if( hitNode.hit.sceneWide )
				{
					waterCollider.entered = true;
					hitWater(colliderNode.motion.x, colliderNode.motion.y, -100, colliderNode, hitNode.entity, hitNode.hit, hitNode.hitAudioData);
					return;
				}
				else 
				{
					hitDisplay = hitNode.display.displayObject;
					if(hitDisplay.hitTestObject(colliderNode.display.displayObject))
					{
						//hitWater(colliderNode.motion.x, colliderNode.motion.y, int(hitDisplay.y - hitDisplay.height), colliderNode, hitNode.entity, hitNode.hit, hitNode.hitAudioData);
						hitWater(colliderNode.motion.x, colliderNode.motion.y, int(hitDisplay.y), colliderNode, hitNode.entity, hitNode.hit, hitNode.hitAudioData);
						return;
					}
				}
			}
			
			// if no collision with water, allow for update margin before deactivating
			if( colliderNode.collider.hitTimer > 0 )
			{
				// decrement timer, necessary for other bitmap collisions, such as walls, so that water does not deactivate immediately
				colliderNode.collider.hitTimer--;
			}
			else
			{
				waterCollider.entered = false;
				waterCollider.isHit = false;
				waterCollider.surface = false;
			}
		}
		
		private function hitWater(x:Number, y:Number, surface:int, colliderNode:WaterCollisionNode, hitEntity:Entity, hit:Water, hitAudioData:HitAudioData):void
		{
			colliderNode.collider.hitTimer = 1;		// necessary for other bitmap collisions, such as walls, so that water does not deactivate immediately
			
			// check densities of collider and hit, determines if colliders sinks or floats
			colliderNode.collider.float = colliderNode.collider.density < hit.density;
			colliderNode.collider.densityHit = hit.density;
			
			// var platformColliders:uint;	// TODO :: not accounting for platforms in this method yet
			var collider:WaterCollider = colliderNode.collider;
			var edge:Edge = colliderNode.edge;
			var motion:Motion = colliderNode.motion;
			
			collider.depth = y + edge.rectangle.bottom - ( surface + collider.surfaceOffset );
			if ( collider.depth > 0)
			{
				collider.isHit = true;
		
				var heightSubmerged:Number = Math.min( collider.depth, (-edge.rectangle.top + edge.rectangle.bottom) );
				collider.percentSubmerged = heightSubmerged/edge.rectangle.height;
		
				var surfacePercent:Number = SURFACE_PERCENT;
				if (collider.isPet)
				{
					// when pet is swimming on top of water, percentSubmerged is 1.0
					surfacePercent = SURFACE_PERCENT_PET;
				}
				
				// if entity is submerged less than percent of total height, it is on the surface.
				collider.surface = ( collider.percentSubmerged < surfacePercent );
				
				//check if colliding entity is on a platform, if so don't apply buoyancy
				if( checkOnPlatform( colliderNode.platformCollider, collider ) )
				{
					return;
				}
			
				var colliderDensity:Number = collider.density;
				// if floatAtSurface flag is true, when near surface adjust collider density to be less than hit density
				if( collider.floatAtSurface )
				{
					if( collider.densityHit != 1 )
					{
						if( collider.surface )
						{
							colliderDensity = Math.max( .1, ( collider.densityHit - (1 - collider.density)));
						}
					}
				}
			
				// if entering initially, dampen velocity on entrance
				// TODO :: This needs more work, temporary adjustment. - Bard
				if( !collider.entered )			
				{
					// surfaceResistance is set within collider
					// TODO :: should take into acccount scale and width. -Bard
					motion.velocity.y *= collider.surfaceResistance;
					
					// NOTE :: Might want to make surface tension/resistance more dynamic in future, for now it is set within the collider
					// surface tension, force = SurfaceTension const * Length, in this case we will use the fluid density as the SurfaceTension const.					
					//var widthUnits:Number = edge.width/100;	// determine width units
					//var resistance:Number = ( 100 - Math.min(100, (edge.width * hit.density)) )/SURFACE_RESISTANCE;
				}
					
				// if collider contains platform hits, take into account possible extra weight before calculating buoyancy
				var i:uint;
				if(colliderNode.platformHit != null)		// if floating object contains platforms...
				{
					if( colliderNode.entityIdList.hasEntities )	// if platform is occupied, adjust weigh
					{
						if( !colliderNode.collider.ignoreSplash )
						{
							// create additional splash for when collider with platform sinks below it's halfway point
							if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
							{
								if( collider.percentSubmerged < .45 )	// if collider is not submerged more than halfway, create splash
								{
									createSplash( colliderNode, x + (Math.random() * -colliderNode.display.displayObject.width + colliderNode.display.displayObject.width * .5), 
										surface, hit.splashColor1, hit.splashColor2, hitAudioData);
								}
							}
						}
						
						// increase weight ( we use density here ) to make collider sink deeper
						for (i = 0; i < colliderNode.entityIdList.entities.length; i++) 
						{
							//entityOnPlatform = colliderNode.entityIdList.entities[i];
							colliderDensity += playerWeight;	//TODO :: temp, make more accurate based on entity mass
						}
					}
				}
				
				// apply buoyancy
				motion.acceleration.y = getBuoyancy( edge, hit.density, colliderDensity, heightSubmerged ) * collider.dampener;
				// apply viscosity of hit to velocity of collider
				motion.velocity.y *= hit.viscosity;	// NOTE :: Don't want to be constantly dampening velocity like this, need a better method. -Bard
				motion.velocity.x *= hit.viscosity;
			}
		
			// happens once each time entity comes into contact with water after being out of it
			if( !collider.entered )
			{
				collider.entered = true;
				if( colliderNode.currentHit )	{ colliderNode.currentHit.hit = hitEntity; }	// set current hit
				if( !colliderNode.collider.ignoreSplash )
				{
					createSplash( colliderNode, x, surface, hit.splashColor1, hit.splashColor2, hitAudioData);
				}
			}

		}
						
		/**
		 * Returns the y position of the surface.
		 * This is used for bitmap water hits. 
		 * @param collider
		 * @return 
		 * 
		 */
		private function getSurface(collider:BitmapCollider):int
		{
			var targetY:int = collider.centerHitY;
			var hitArea:BitmapData = _hitAreaNode.bitmapHitArea.bitmapData;
			var hitAreaSpatial:Spatial = _hitAreaNode.spatial;
			
			while(hitArea.getPixel(collider.centerHitX * hitAreaSpatial.scale + hitAreaSpatial.x, targetY * hitAreaSpatial.scale + hitAreaSpatial.y) == collider.centerColor)
			{
				targetY--;
			}
			
			return(targetY);
		}
		
		/**
		 * Determines if colliding entity should stick to platform 
		 * @param platformCollider
		 * @param collider
		 * @return 
		 */
		private function checkOnPlatform( platformCollider:PlatformCollider, collider:WaterCollider ):Boolean
		{
			if( platformCollider != null && platformCollider.isHit )
			{
				if( collider.surface )
				{
					return true;
				}
				else if( !collider.float )
				{
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Buoyancy is equal to the volume of the submerged object * the density of liquid displaced * gravity.
		 * In other words buoyancy is equal to the weight of the volume of liquid that has been displaced.
		 * TODO :: Needs to be integrated with other 'physics' systems
		 */
		private function getBuoyancy( colliderEdge:Edge, hitDensity:Number, colliderDensity:Number, heightSubmerged:Number ):Number
		{
			//determine volume submerged (does not currently account for rotation)
			var volumeSubmerged:Number = (colliderEdge.rectangle.width * heightSubmerged)/1000;
			var volumeTotal:Number = (colliderEdge.rectangle.width * colliderEdge.rectangle.height)/1000;
			
			var pressure:Number = (volumeSubmerged * hitDensity) * MotionUtils.GRAVITY;			
			var gravity:Number = (volumeTotal * colliderDensity) * MotionUtils.GRAVITY;
			return (gravity - pressure);
		}
		
		private function createSplash( node:WaterCollisionNode, x:Number, y:Number, color1:uint, color2:uint, hitAudioData:HitAudioData):void
		{
			var container:DisplayObjectContainer = node.display.container;
			var motion:Motion = node.motion;
			
			// create splash
			var velocityFactor:Number = 1;
			if(motion.maxVelocity != null)
			{
				velocityFactor = Math.abs(motion.velocity.y / motion.maxVelocity.y);
				velocityFactor += .5;
				velocityFactor = Math.min(velocityFactor, 1);
			}
			var splashEmitter:WaterSplash = new WaterSplash();
			splashEmitter.init(velocityFactor, color1, color2);
			
			var splash:Entity = EmitterCreator.create(super.group, container, splashEmitter);	
			splash.get(Spatial).x = x;
			splash.get(Spatial).y = y;
			splash.add(new Sleep());
			Emitter(splash.get(Emitter)).remove = true;
			Emitter(splash.get(Emitter)).removeOnSleep = true;
			
			// play audio
			EntityUtils.playAudioAction(node.hitAudio, hitAudioData);
		}
		
		private var _hits:NodeList;
		private var _bitmapHits:NodeList;
		private var _nodes:NodeList;
		private var _hitAreaNode:BitmapHitAreaNode;
		private var _hitAreaNodes:NodeList;
		public var playerWeight:Number = .2;
		private const SURFACE_PERCENT:Number = 1;
		private const SURFACE_PERCENT_PET:Number = 1.01;
		private const WATER_SURFACE_OFFSET:Number = 0;
		private const DENSITY_OFFSET:Number = .3;	// how much to offset density to make colliding entity float along surface (use for characters0
	}
}
